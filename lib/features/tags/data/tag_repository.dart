import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/tag.dart';
import '../../../core/db/local_db.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/sync/sync_store.dart';
import 'local_tag_store.dart';

class TagRepository {
  TagRepository(this.ref)
      : _local = LocalTagStore(LocalDb.instance),
        _sync = SyncStore(LocalDb.instance);

  final Ref ref;
  final LocalTagStore _local;
  final SyncStore _sync;
  final _uuid = const Uuid();

  Future<List<Tag>> fetchTags() async {
    final items = await _local.list();
    ref.read(syncServiceProvider).sync();
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
}

final tagRepositoryProvider = Provider<TagRepository>((ref) => TagRepository(ref));
