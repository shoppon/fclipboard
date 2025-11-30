import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_client.dart';
import '../../../core/data/tag.dart';
import '../../../core/db/local_db.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/sync/sync_store.dart';
import 'local_tag_store.dart';

class TagRepository {
  TagRepository(this.ref)
      : _local = LocalTagStore(LocalDb.instance),
        _sync = SyncStore(LocalDb.instance),
        _api = ref.read(apiClientProvider);

  final Ref ref;
  final LocalTagStore _local;
  final SyncStore _sync;
  final ApiClient _api;
  final _uuid = const Uuid();

  Future<List<Tag>> fetchTags() async {
    final items = await _local.list();
    return items;
  }

  Future<Tag> createTag({required String name, String? color}) async {
    final tag = Tag(
      id: _uuid.v4(),
      name: name,
      color: color,
      updatedAt: DateTime.now(),
      version: 1,
    );
    await _local.upsert(tag);
    await _sync.enqueue(
      entityType: 'tag',
      entityId: tag.id,
      op: 'upsert',
      payload: {
        'id': tag.id,
        'name': tag.name,
        'color': tag.color,
        'version': tag.version,
        'updated_at': tag.updatedAt.toIso8601String(),
        'created_at': tag.updatedAt.toIso8601String(),
      },
    );
    ref.read(syncServiceProvider).sync();
    return tag;
  }

  Future<void> dedupeByName(List<Tag> tags) async {
    final seen = <String, Tag>{};
    final toDelete = <String>[];
    for (final t in tags) {
      final existing = seen[t.name];
      if (existing == null || t.updatedAt.isAfter(existing.updatedAt)) {
        if (existing != null) toDelete.add(existing.id);
        seen[t.name] = t;
      } else {
        toDelete.add(t.id);
      }
    }
    if (toDelete.isNotEmpty) {
      await _local.deleteByIds(toDelete);
    }
  }

  Future<void> updateTag({required Tag tag, required String name, String? color}) async {
    final updated = tag.copyWith(
      name: name,
      color: color,
      updatedAt: DateTime.now(),
      version: tag.version + 1,
    );
    await _local.upsert(updated);
    await _sync.enqueue(
      entityType: 'tag',
      entityId: updated.id,
      op: 'upsert',
      payload: {
        'id': updated.id,
        'name': updated.name,
        'color': updated.color,
        'version': updated.version,
        'updated_at': updated.updatedAt.toIso8601String(),
        'created_at': updated.updatedAt.toIso8601String(),
      },
    );
    ref.read(syncServiceProvider).sync();
  }

  Future<void> deleteTag(String id) async {
    await _local.delete(id);
    try {
      await _api.delete('/tags/$id');
    } catch (_) {
      // ignore; next sync pull will refresh local state
    }
    ref.read(syncServiceProvider).sync();
  }
}

final tagRepositoryProvider = Provider<TagRepository>((ref) => TagRepository(ref));
