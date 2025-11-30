import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/data/snippet.dart';
import '../../../core/db/local_db.dart';

class LocalSnippetStore {
  LocalSnippetStore(this._dbProvider);

  final LocalDb _dbProvider;

  Future<List<Snippet>> list({String? tagId}) async {
    final db = await _dbProvider.database;
    final where = StringBuffer('(deleted_at IS NULL OR deleted_at = \'\' )');
    final args = <Object?>[];
    if (tagId != null) {
      where.write(' AND tag_id = ?');
      args.add(tagId);
    }
    final rows = await db.query(
      'snippets',
      where: where.toString(),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'updated_at DESC',
    );
    return rows.map(_mapRow).toList();
  }

  Future<List<Snippet>> listAll() async {
    final db = await _dbProvider.database;
    final rows = await db.query(
      'snippets',
      where: '(deleted_at IS NULL OR deleted_at = \'\')',
      orderBy: 'updated_at DESC',
    );
    return rows.map(_mapRow).toList();
  }

  Future<void> upsert(Snippet snippet) async {
    final db = await _dbProvider.database;
    await db.insert(
      'snippets',
      {
        'id': snippet.id,
        'title': snippet.title,
        'body': snippet.body,
        'tags': jsonEncode(snippet.tags),
        'source': snippet.source,
        'pinned': snippet.pinned ? 1 : 0,
        'parameters':
            jsonEncode(snippet.parameters.map((p) => p.toJson()).toList()),
        'version': snippet.version,
        'created_at': snippet.createdAt.toIso8601String(),
        'updated_at': snippet.updatedAt.toIso8601String(),
        'deleted_at': snippet.deletedAt?.toIso8601String(),
        'conflict_of': snippet.conflictOf,
        'tag_id': snippet.tagId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Snippet _mapRow(Map<String, Object?> r) {
    return Snippet(
      id: r['id'] as String,
      title: (r['title'] as String?) ?? '',
      body: (r['body'] as String?) ?? '',
      tags: _decodeList(r['tags'] as String?),
      source: r['source'] as String?,
      pinned: (r['pinned'] as int? ?? 0) == 1,
      parameters: _decodeParams(r['parameters'] as String?),
      version: (r['version'] as int?) ?? 1,
      createdAt: DateTime.tryParse((r['created_at'] as String?) ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse((r['updated_at'] as String?) ?? '') ??
          DateTime.now(),
      deletedAt: r['deleted_at'] != null
          ? DateTime.tryParse(r['deleted_at'] as String)
          : null,
      conflictOf: r['conflict_of'] as String?,
      tagId: r['tag_id'] as String?,
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

  Future<Map<String?, int>> countByTag() async {
    final db = await _dbProvider.database;
    final rows = await db.rawQuery(
      '''
        SELECT tag_id, COUNT(*) as cnt
        FROM snippets
        WHERE (deleted_at IS NULL OR deleted_at = '')
        GROUP BY tag_id
      ''',
    );
    final counts = <String?, int>{};
    for (final r in rows) {
      final tagId = r['tag_id'] as String?;
      final cnt = (r['cnt'] as int?) ?? 0;
      counts[tagId] = cnt;
    }
    return counts;
  }

  Future<void> pruneNotIn(Set<String> ids) async {
    final db = await _dbProvider.database;
    if (ids.isEmpty) {
      await db.delete('snippets');
      return;
    }
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.delete('snippets',
        where: 'id NOT IN ($placeholders)', whereArgs: ids.toList());
  }

  Future<void> deleteByIds(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await _dbProvider.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.delete('snippets', where: 'id IN ($placeholders)', whereArgs: ids);
  }
}
