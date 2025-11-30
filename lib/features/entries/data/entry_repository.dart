import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/entry.dart';
import '../../../core/db/local_db.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/sync/sync_store.dart';
import 'local_entry_store.dart';

class EntryRepository {
  EntryRepository(this.ref)
      : _local = LocalEntryStore(LocalDb.instance),
        _sync = SyncStore(LocalDb.instance);

  final Ref ref;
  final LocalEntryStore _local;
  final SyncStore _sync;
  final _uuid = const Uuid();

  Future<List<Entry>> fetchEntries({String query = "", String? categoryId}) async {
    final entries = await _local.list(categoryId: categoryId);
    final filtered = query.isEmpty
        ? entries
        : entries
            .where((e) => e.title.toLowerCase().contains(query.toLowerCase()) || e.body.toLowerCase().contains(query.toLowerCase()))
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    // Fire-and-forget sync to refresh data
    ref.read(syncServiceProvider).sync();
    return filtered;
  }

  Future<Entry> createEntry({
    required String title,
    required String body,
    String? categoryId,
    List<String> tags = const [],
    List<EntryParameter> parameters = const [],
  }) async {
    final now = DateTime.now();
    final entry = Entry(
      id: _uuid.v4(),
      title: title,
      body: body,
      createdAt: now,
      updatedAt: now,
      version: 1,
      tags: tags,
      categoryId: categoryId,
      parameters: parameters,
      pinned: false,
    );
    await _local.upsert(entry);
    await _sync.enqueue(
      entityType: 'entry',
      entityId: entry.id,
      op: 'upsert',
      payload: _entryToJson(entry),
    );
    ref.read(syncServiceProvider).sync();
    return entry;
  }

  Future<Entry> togglePin(Entry entry) async {
    final updated = entry.copyWith(pinned: !entry.pinned, updatedAt: DateTime.now(), version: entry.version + 1);
    await _local.upsert(updated);
    await _sync.enqueue(
      entityType: 'entry',
      entityId: updated.id,
      op: 'upsert',
      payload: _entryToJson(updated),
    );
    ref.read(syncServiceProvider).sync();
    return updated;
  }

  Map<String, dynamic> _entryToJson(Entry entry) {
    return {
      'id': entry.id,
      'title': entry.title,
      'body': entry.body,
      'tags': entry.tags,
      'source': entry.source,
      'pinned': entry.pinned,
      'parameters': entry.parameters.map((p) => p.toJson()).toList(),
      'version': entry.version,
      'created_at': entry.createdAt.toIso8601String(),
      'updated_at': entry.updatedAt.toIso8601String(),
      'deleted_at': entry.deletedAt?.toIso8601String(),
      'conflict_of': entry.conflictOf,
      'category_id': entry.categoryId,
    };
  }
}

final entryRepositoryProvider = Provider<EntryRepository>((ref) => EntryRepository(ref));
