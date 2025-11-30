import 'package:sqflite/sqflite.dart';

import '../../../core/data/category.dart';
import '../../../core/db/local_db.dart';

class LocalCategoryStore {
  LocalCategoryStore(this._dbProvider);

  final LocalDb _dbProvider;

  Future<List<Category>> list() async {
    final db = await _dbProvider.database;
    final rows = await db.query('categories', orderBy: 'updated_at DESC');
    return rows
        .map(
          (r) => Category(
            id: r['id'] as String,
            name: (r['name'] as String?) ?? '',
            color: r['color'] as String?,
            version: (r['version'] as int?) ?? 1,
            updatedAt: DateTime.tryParse((r['updated_at'] as String?) ?? '') ?? DateTime.now(),
          ),
        )
        .toList();
  }

  Future<void> upsert(Category category, {String? userId}) async {
    final db = await _dbProvider.database;
    await db.insert(
      'categories',
      {
        'id': category.id,
        'name': category.name,
        'color': category.color,
        'version': category.version,
        'updated_at': category.updatedAt.toIso8601String(),
        'user_id': userId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
