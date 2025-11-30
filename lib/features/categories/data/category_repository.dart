import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/category.dart';
import '../../../core/db/local_db.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/sync/sync_store.dart';
import 'local_category_store.dart';

class CategoryRepository {
  CategoryRepository(this.ref)
      : _local = LocalCategoryStore(LocalDb.instance),
        _sync = SyncStore(LocalDb.instance);

  final Ref ref;
  final LocalCategoryStore _local;
  final SyncStore _sync;
  final _uuid = const Uuid();

  Future<List<Category>> fetchCategories() async {
    final items = await _local.list();
    ref.read(syncServiceProvider).sync();
    return items;
  }

  Future<Category> createCategory({required String name, String? color}) async {
    final category = Category(
      id: _uuid.v4(),
      name: name,
      color: color,
      updatedAt: DateTime.now(),
      version: 1,
    );
    await _local.upsert(category);
    await _sync.enqueue(
      entityType: 'category',
      entityId: category.id,
      op: 'upsert',
      payload: {
        'id': category.id,
        'name': category.name,
        'color': category.color,
        'version': category.version,
        'updated_at': category.updatedAt.toIso8601String(),
        'created_at': category.updatedAt.toIso8601String(),
      },
    );
    ref.read(syncServiceProvider).sync();
    return category;
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) => CategoryRepository(ref));
