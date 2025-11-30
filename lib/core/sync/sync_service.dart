import 'dart:convert';
import 'dart:typed_data';

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

  DateTime _clampToNow(DateTime ts) {
    final now = DateTime.now();
    return ts.isAfter(now) ? now : ts;
  }

  Map<String, Tag> _dedupeTagsByName(Iterable<Tag> items) {
    final map = <String, Tag>{};
    for (final t in items) {
      final existing = map[t.name];
      if (existing == null || t.updatedAt.isAfter(existing.updatedAt)) {
        map[t.name] = t;
      }
    }
    return map;
  }

  Map<String, Snippet> _dedupeSnippetsByTitle(Iterable<Snippet> items) {
    final map = <String, Snippet>{};
    for (final s in items) {
      final existing = map[s.title];
      if (existing == null || s.updatedAt.isAfter(existing.updatedAt)) {
        map[s.title] = s;
      }
    }
    return map;
  }

  Future<void> _syncTags() async {
    try {
      var savedCount = 0;
      final pending = await syncStore.pending('tag');
      if (pending.isNotEmpty) {
        final payload = {
          'tags': pending.map((p) => p.payload).toList(),
        };
        final res = await api.post('/tags/sync', body: payload);
        if (res.statusCode >= 200 && res.statusCode < 300) {
          await syncStore.deleteOps(pending.map((e) => e.id).toList());
        }
      }

      // Force full fetch; page forward by page number.
      DateTime? maxTs;
      final seenIds = <String>{};
      const limit = 100;
      var page = 1;
      while (true) {
        final res = await api.get('/tags?limit=$limit&page=$page');
        if (res.statusCode != 200) break;
        final list = _decodeJsonList(res.bodyBytes);
        if (list.isEmpty) break;
        final mapped = list.map((item) => _mapTag(item as Map<String, dynamic>));
        final deduped = _dedupeTagsByName(mapped);
        for (final c in deduped.values) {
          seenIds.add(c.id);
          try {
            await tags.upsert(c);
            savedCount++;
          } catch (e) {
            debugPrint('tag upsert failed id=${c.id} name=${c.name} err=$e');
          }
          if (maxTs == null || c.updatedAt.isAfter(maxTs)) maxTs = c.updatedAt;
        }
        if (list.length < limit) break;
        page += 1;
      }
      if (maxTs != null) {
        await syncStore.setLastSynced('tags', _clampToNow(maxTs));
      }
      if (seenIds.isNotEmpty) {
        await tags.pruneNotIn(seenIds);
      }
      debugPrint(
          'sync tags done fetched=${seenIds.length} saved=$savedCount pending=${pending.length} maxTs=$maxTs');
    } catch (e) {
      // swallow errors to stay offline-friendly
      debugPrint('sync tags error: $e');
    }
  }

  Future<void> _syncSnippets() async {
    try {
      var savedCount = 0;
      final pending = await syncStore.pending('snippet');
      if (pending.isNotEmpty) {
        final payload = {
          'snippets': pending.map((p) => p.payload).toList(),
        };
        final res = await api.post('/snippets/sync', body: payload);
        if (res.statusCode >= 200 && res.statusCode < 300) {
          await syncStore.deleteOps(pending.map((e) => e.id).toList());
        }
      }

      // Always start from scratch; page forward by page number.
      DateTime? maxTs;
      final seenIds = <String>{};
      const limit = 100;
      var page = 1;
      while (true) {
        final res = await api.get('/snippets?limit=$limit&page=$page');
        if (res.statusCode != 200) break;
        final list = _decodeJsonList(res.bodyBytes);
        if (list.isEmpty) break;
        final mapped =
            list.map((item) => _mapSnippet(item as Map<String, dynamic>));
        final deduped = _dedupeSnippetsByTitle(mapped);
        for (final e in deduped.values) {
          seenIds.add(e.id);
          try {
            await snippets.upsert(e);
            savedCount++;
          } catch (err) {
            debugPrint('snippet upsert failed id=${e.id} title=${e.title} err=$err');
          }
          if (maxTs == null || e.updatedAt.isAfter(maxTs)) maxTs = e.updatedAt;
        }
        if (list.length < limit) break;
        page += 1;
      }
      if (maxTs != null) {
        await syncStore.setLastSynced('snippets', _clampToNow(maxTs));
      }
      if (seenIds.isNotEmpty && pending.isEmpty) {
        await snippets.pruneNotIn(seenIds);
      }
      debugPrint(
          'sync snippets done fetched=${seenIds.length} saved=$savedCount pending=${pending.length} maxTs=$maxTs');
    } catch (e) {
      // offline or server error; will retry later
      debugPrint('sync snippets error: $e');
    }
  }

  List<dynamic> _decodeJsonList(Uint8List bodyBytes) {
    return jsonDecode(utf8.decode(bodyBytes)) as List<dynamic>;
  }

  Tag _mapTag(Map<String, dynamic> json) {
    return Tag(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      color: json['color'] as String?,
      version: (json['version'] as num?)?.toInt() ?? 1,
      updatedAt: DateTime.parse(json['updated_at'].toString()),
    );
  }

  Snippet _mapSnippet(Map<String, dynamic> json) {
    return Snippet(
      id: (json['id'] ?? const Uuid().v4()).toString(),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>? ?? []).cast<String>(),
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
      tagId: json['tag_id']?.toString(),
    );
  }
}
