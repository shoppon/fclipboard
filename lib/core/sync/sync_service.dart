import 'dart:convert';

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
  return SyncService(api: api, snippets: snippetStore, tags: tagStore, syncStore: syncStore);
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

  Future<void> _syncTags() async {
    try {
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

      final last = await syncStore.lastSynced('tags');
      final query = last != null ? '?updatedAfter=${last.toIso8601String()}' : '';
      final res = await api.get('/tags$query');
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        DateTime? maxTs = last;
        for (final item in list) {
          final c = _mapTag(item as Map<String, dynamic>);
          await tags.upsert(c);
          if (maxTs == null || c.updatedAt.isAfter(maxTs)) maxTs = c.updatedAt;
        }
        if (maxTs != null) {
          await syncStore.setLastSynced('tags', maxTs);
        }
      }
    } catch (_) {
      // swallow errors to stay offline-friendly
    }
  }

  Future<void> _syncSnippets() async {
    try {
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

      final last = await syncStore.lastSynced('snippets');
      final query = last != null ? '?updatedAfter=${last.toIso8601String()}' : '';
      final res = await api.get('/snippets$query');
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        DateTime? maxTs = last;
        for (final item in list) {
          final e = _mapSnippet(item as Map<String, dynamic>);
          await snippets.upsert(e);
          if (maxTs == null || e.updatedAt.isAfter(maxTs)) maxTs = e.updatedAt;
        }
        if (maxTs != null) {
          await syncStore.setLastSynced('snippets', maxTs);
        }
      }
    } catch (_) {
      // offline or server error; will retry later
    }
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
      createdAt: DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now(),
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
      conflictOf: json['conflict_of']?.toString(),
      tagId: json['tag_id']?.toString(),
    );
  }
}
