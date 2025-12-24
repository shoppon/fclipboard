import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../features/tags/data/local_tag_store.dart';
import '../../features/snippets/data/local_snippet_store.dart';
import '../data/tag.dart';
import '../data/snippet.dart';
import '../db/local_db.dart';
import '../api/api_client.dart';
import 'sync_store.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final api = ref.read(apiClientProvider);
  final localDb = LocalDb.instance;
  final snippetStore = LocalSnippetStore(localDb);
  final tagStore = LocalTagStore(localDb);
  final syncStore = SyncStore(localDb);
  return SyncService(
      api: api, snippets: snippetStore, tags: tagStore, syncStore: syncStore);
});

class SyncService {
  SyncService({
    required this.api,
    required this.snippets,
    required this.tags,
    required this.syncStore,
  });

  final ApiClient api;
  final LocalSnippetStore snippets;
  final LocalTagStore tags;
  final SyncStore syncStore;
  bool _busy = false;

  Future<void> sync() async {
    if (_busy) return;
    _busy = true;
    try {
      await _syncTags();
      await _syncSnippets();
    } finally {
      _busy = false;
    }
  }

  Future<void> downloadAll() async {
    if (_busy) return;
    _busy = true;
    try {
      await _downloadTags();
      await _downloadSnippets();
    } finally {
      _busy = false;
    }
  }

  Future<DateTime?> _safeLastSynced(String key) async {
    final last = await syncStore.lastSynced(key);
    if (last == null) return null;
    final now = DateTime.now();
    if (last.isBefore(DateTime(2000))) {
      return null;
    }
    if (last.isAfter(now)) {
      // Clock skew or bad data; reset so we don't skip pulls forever.
      await syncStore.setLastSynced(key, now);
      return null;
    }
    return last;
  }

  Future<void> _syncTags() async {
    try {
      final pending = await syncStore.pending('tag');
      final cursor = await _safeLastSynced('tags_cursor');
      final payload = <String, dynamic>{
        'cursor': cursor?.toIso8601String(),
        'ops': pending
            .map((p) => {
                  'op': p.op,
                  'tag': p.payload,
                })
            .toList(),
      }..removeWhere(
          (_, value) => value == null || (value is List && value.isEmpty));

      final res = await api.post('/tags/sync', body: payload);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('tags sync failed with status ${res.statusCode}');
      }
      final data =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (pending.isNotEmpty) {
        await syncStore.deleteOps(pending.map((e) => e.id).toList());
      }
      final changes = (data['changes'] as List<dynamic>? ?? [])
          .map((item) => _mapTag(item as Map<String, dynamic>))
          .toList();
      for (final t in changes) {
        if (t.deletedAt != null) {
          await tags.delete(t.id);
        } else {
          await tags.upsert(t);
        }
      }
      final nextCursorStr = data['nextCursor'] as String?;
      if (nextCursorStr != null && nextCursorStr.isNotEmpty) {
        await syncStore.setLastSynced(
            'tags_cursor', DateTime.parse(nextCursorStr));
      }
      debugPrint(
          'sync tags done changes=${changes.length} pending=${pending.length}');
    } catch (e) {
      // swallow errors to stay offline-friendly
      debugPrint('sync tags error: $e');
    }
  }

  Future<void> _syncSnippets() async {
    try {
      final pending = await syncStore.pending('snippet');
      final cursor = await _safeLastSynced('snippets_cursor');
      final payload = <String, dynamic>{
        'cursor': cursor?.toIso8601String(),
        'ops': pending
            .map((p) => {
                  'op': p.op,
                  'snippet': p.payload,
                })
            .toList(),
      }..removeWhere(
          (_, value) => value == null || (value is List && value.isEmpty));

      final res = await api.post('/snippets/sync', body: payload);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('snippets sync failed with status ${res.statusCode}');
      }
      final data =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (pending.isNotEmpty) {
        await syncStore.deleteOps(pending.map((e) => e.id).toList());
      }
      final changes = (data['changes'] as List<dynamic>? ?? [])
          .map((item) => _mapSnippet(item as Map<String, dynamic>))
          .toList();
      for (final s in changes) {
        await snippets.upsert(s);
      }
      final nextCursorStr = data['nextCursor'] as String?;
      if (nextCursorStr != null && nextCursorStr.isNotEmpty) {
        await syncStore.setLastSynced(
            'snippets_cursor', DateTime.parse(nextCursorStr));
      }
      debugPrint(
          'sync snippets done changes=${changes.length} pending=${pending.length}');
    } catch (e) {
      // offline or server error; will retry later
      debugPrint('sync snippets error: $e');
    }
  }

  Future<void> _downloadTags() async {
    try {
      final pending = await syncStore.pending('tag');
      final pendingDeletes = pending
          .where((op) => op.op == 'delete')
          .map((op) => op.entityId)
          .toSet();
      final ids = <String>{};
      DateTime? maxTs;
      const limit = 200;
      var page = 1;
      while (true) {
        final res = await api.get('/tags/full?limit=$limit&page=$page');
        if (res.statusCode != 200) {
          throw Exception(
              'full tags fetch failed with status ${res.statusCode}');
        }
        final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
        if (list.isEmpty) break;
        final mapped =
            list.map((item) => _mapTag(item as Map<String, dynamic>)).toList();
        for (final t in mapped) {
          ids.add(t.id);
          if (pendingDeletes.contains(t.id)) {
            // Keep local tombstone; do not resurrect remote copy.
            continue;
          }
          await tags.upsert(t);
          final ts = t.deletedAt ?? t.updatedAt;
          if (maxTs == null || ts.isAfter(maxTs)) maxTs = ts;
        }
        if (list.length < limit) break;
        page += 1;
      }
      if (ids.isNotEmpty) {
        await tags.pruneNotIn(ids);
      }
      if (maxTs != null) {
        await syncStore.setLastSynced('tags_cursor', maxTs);
      }
      debugPrint('download all tags done count=${ids.length}');
    } catch (e) {
      debugPrint('download all tags error: $e');
    }
  }

  Future<void> _downloadSnippets() async {
    try {
      final pending = await syncStore.pending('snippet');
      final pendingDeletes = pending
          .where((op) => op.op == 'delete')
          .map((op) => op.entityId)
          .toSet();
      final ids = <String>{};
      DateTime? maxTs;
      const limit = 200;
      var page = 1;
      while (true) {
        final res = await api.get('/snippets/full?limit=$limit&page=$page');
        if (res.statusCode != 200) {
          throw Exception(
              'full snippets fetch failed with status ${res.statusCode}');
        }
        final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
        if (list.isEmpty) break;
        final mapped = list
            .map((item) => _mapSnippet(item as Map<String, dynamic>))
            .toList();
        for (final s in mapped) {
          ids.add(s.id);
          if (pendingDeletes.contains(s.id)) {
            // Keep local tombstone; do not resurrect remote copy.
            continue;
          }
          await snippets.upsert(s);
          final ts = s.deletedAt ?? s.updatedAt;
          if (maxTs == null || ts.isAfter(maxTs)) maxTs = ts;
        }
        if (list.length < limit) break;
        page += 1;
      }
      if (ids.isNotEmpty) {
        await snippets.pruneNotIn(ids);
      }
      if (maxTs != null) {
        await syncStore.setLastSynced('snippets_cursor', maxTs);
      }
      debugPrint('download all snippets done count=${ids.length}');
    } catch (e) {
      debugPrint('download all snippets error: $e');
    }
  }

  Tag _mapTag(Map<String, dynamic> json) {
    return Tag(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      color: json['color'] as String?,
      version: (json['version'] as num?)?.toInt() ?? 1,
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'].toString())
          : null,
    );
  }

  Snippet _mapSnippet(Map<String, dynamic> json) {
    return Snippet(
      id: (json['id'] ?? const Uuid().v4()).toString(),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      tagIds: (json['tag_ids'] as List<dynamic>? ?? []).cast<String>(),
      source: json['source'] as String?,
      pinned: json['pinned'] as bool? ?? false,
      parameters: (json['parameters'] as List<dynamic>? ?? [])
          .map((e) => EntryParameter.fromJson(e as Map<String, dynamic>))
          .toList(),
      version: (json['version'] as num?)?.toInt() ?? 1,
      createdAt:
          DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now(),
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'].toString())
          : null,
      conflictOf: json['conflict_of']?.toString(),
    );
  }
}
