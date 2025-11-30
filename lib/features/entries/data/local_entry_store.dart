import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/data/entry.dart';
import '../../../core/db/local_db.dart';

class LocalEntryStore {
  LocalEntryStore(this._dbProvider);

  final LocalDb _dbProvider;

  Future<List<Entry>> list({String? categoryId}) async {
    final db = await _dbProvider.database;
    final where = StringBuffer('(deleted_at IS NULL OR deleted_at = \'\' )');
    final args = <Object?>[];
    if (categoryId != null) {
      where.write(' AND category_id = ?');
      args.add(categoryId);
    }
    final rows = await db.query(
      'entries',
      where: where.toString(),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'updated_at DESC',
    );
    return rows.map(_mapRow).toList();
  }

  Future<void> upsert(Entry entry) async {
    final db = await _dbProvider.database;
    await db.insert(
      'entries',
      {
        'id': entry.id,
        'title': entry.title,
        'body': entry.body,
        'tags': jsonEncode(entry.tags),
        'source': entry.source,
        'pinned': entry.pinned ? 1 : 0,
        'parameters': jsonEncode(entry.parameters.map((p) => p.toJson()).toList()),
        'version': entry.version,
        'created_at': entry.createdAt.toIso8601String(),
        'updated_at': entry.updatedAt.toIso8601String(),
        'deleted_at': entry.deletedAt?.toIso8601String(),
        'conflict_of': entry.conflictOf,
        'category_id': entry.categoryId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Entry _mapRow(Map<String, Object?> r) {
    return Entry(
      id: r['id'] as String,
      title: (r['title'] as String?) ?? '',
      body: (r['body'] as String?) ?? '',
      tags: _decodeList(r['tags'] as String?),
      source: r['source'] as String?,
      pinned: (r['pinned'] as int? ?? 0) == 1,
      parameters: _decodeParams(r['parameters'] as String?),
      version: (r['version'] as int?) ?? 1,
      createdAt: DateTime.tryParse((r['created_at'] as String?) ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse((r['updated_at'] as String?) ?? '') ?? DateTime.now(),
      deletedAt: r['deleted_at'] != null ? DateTime.tryParse(r['deleted_at'] as String) : null,
      conflictOf: r['conflict_of'] as String?,
      categoryId: r['category_id'] as String?,
    );
  }

  List<String> _decodeList(String? data) {
    if (data == null) return [];
    try {
      return (jsonDecode(data) as List<dynamic>).cast<String>();
    } catch (_) {
      return [];
    }
  }

  List<EntryParameter> _decodeParams(String? data) {
    if (data == null) return [];
    try {
      return (jsonDecode(data) as List<dynamic>)
          .map((e) => EntryParameter.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
