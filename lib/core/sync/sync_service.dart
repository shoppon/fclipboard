import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../features/categories/data/local_category_store.dart';
import '../../features/entries/data/local_entry_store.dart';
import '../data/category.dart';
import '../data/entry.dart';
import '../db/local_db.dart';
import '../api/api_client.dart';
import 'sync_store.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final api = ref.read(apiClientProvider);
  final localDb = LocalDb.instance;
  final entryStore = LocalEntryStore(localDb);
  final categoryStore = LocalCategoryStore(localDb);
  final syncStore = SyncStore(localDb);
  return SyncService(api: api, entries: entryStore, categories: categoryStore, syncStore: syncStore);
});

class SyncService {
  SyncService({
    required this.api,
    required this.entries,
    required this.categories,
    required this.syncStore,
  });

  final ApiClient api;
  final LocalEntryStore entries;
  final LocalCategoryStore categories;
  final SyncStore syncStore;
  bool _busy = false;

  Future<void> sync() async {
    if (_busy) return;
    _busy = true;
    try {
      await _syncCategories();
      await _syncEntries();
    } finally {
      _busy = false;
    }
  }

  Future<void> _syncCategories() async {
    try {
      final pending = await syncStore.pending('category');
      if (pending.isNotEmpty) {
        final payload = {
          'categories': pending.map((p) => p.payload).toList(),
        };
        final res = await api.post('/categories/sync', body: payload);
        if (res.statusCode >= 200 && res.statusCode < 300) {
          await syncStore.deleteOps(pending.map((e) => e.id).toList());
        }
      }

      final last = await syncStore.lastSynced('categories');
      final query = last != null ? '?updatedAfter=${last.toIso8601String()}' : '';
      final res = await api.get('/categories$query');
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        DateTime? maxTs = last;
        for (final item in list) {
          final c = _mapCategory(item as Map<String, dynamic>);
          await categories.upsert(c);
          if (maxTs == null || c.updatedAt.isAfter(maxTs)) maxTs = c.updatedAt;
        }
        if (maxTs != null) {
          await syncStore.setLastSynced('categories', maxTs);
        }
      }
    } catch (_) {
      // swallow errors to stay offline-friendly
    }
  }

  Future<void> _syncEntries() async {
    try {
      final pending = await syncStore.pending('entry');
      if (pending.isNotEmpty) {
        final payload = {
          'entries': pending.map((p) => p.payload).toList(),
        };
        final res = await api.post('/entries/sync', body: payload);
        if (res.statusCode >= 200 && res.statusCode < 300) {
          await syncStore.deleteOps(pending.map((e) => e.id).toList());
        }
      }

      final last = await syncStore.lastSynced('entries');
      final query = last != null ? '?updatedAfter=${last.toIso8601String()}' : '';
      final res = await api.get('/entries$query');
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        DateTime? maxTs = last;
        for (final item in list) {
          final e = _mapEntry(item as Map<String, dynamic>);
          await entries.upsert(e);
          if (maxTs == null || e.updatedAt.isAfter(maxTs)) maxTs = e.updatedAt;
        }
        if (maxTs != null) {
          await syncStore.setLastSynced('entries', maxTs);
        }
      }
    } catch (_) {
      // offline or server error; will retry later
    }
  }

  Category _mapCategory(Map<String, dynamic> json) {
    return Category(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      color: json['color'] as String?,
      version: (json['version'] as num?)?.toInt() ?? 1,
      updatedAt: DateTime.parse(json['updated_at'].toString()),
    );
  }

  Entry _mapEntry(Map<String, dynamic> json) {
    return Entry(
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
      categoryId: json['category_id']?.toString(),
    );
  }
}
