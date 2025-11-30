import 'package:sqflite/sqflite.dart';

import '../../../core/data/tag.dart';
import '../../../core/db/local_db.dart';

class LocalTagStore {
  LocalTagStore(this._dbProvider);

  final LocalDb _dbProvider;

  Future<List<Tag>> list() async {
    final db = await _dbProvider.database;
    final rows = await db.query('tags', orderBy: 'updated_at DESC');
    return rows
        .map(
          (r) => Tag(
            id: r['id'] as String,
            name: (r['name'] as String?) ?? '',
            color: r['color'] as String?,
            version: (r['version'] as int?) ?? 1,
            updatedAt: DateTime.tryParse((r['updated_at'] as String?) ?? '') ?? DateTime.now(),
          ),
        )
        .toList();
  }

  Future<void> upsert(Tag tag, {String? userId}) async {
    final db = await _dbProvider.database;
    await db.insert(
      'tags',
      {
        'id': tag.id,
        'name': tag.name,
        'color': tag.color,
        'version': tag.version,
        'updated_at': tag.updatedAt.toIso8601String(),
        'user_id': userId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final db = await _dbProvider.database;
    await db.delete('tags', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteByIds(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await _dbProvider.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.delete('tags', where: 'id IN ($placeholders)', whereArgs: ids);
  }

  Future<void> pruneNotIn(Set<String> ids) async {
    final db = await _dbProvider.database;
    final placeholders = ids.isEmpty ? '' : List.filled(ids.length, '?').join(',');
    if (ids.isEmpty) {
      await db.delete('tags');
      return;
    }
    await db.delete('tags', where: 'id NOT IN ($placeholders)', whereArgs: ids.toList());
  }
}
