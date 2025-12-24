import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/data/snippet.dart';
import '../../../core/db/local_db.dart';

class LocalSnippetStore {
  LocalSnippetStore(this._dbProvider);

  final LocalDb _dbProvider;

  Future<List<Snippet>> list({String? tagId}) async {
    final db = await _dbProvider.database;
    final rows = await db.query(
      'snippets',
      where: '(deleted_at IS NULL OR deleted_at = \'\')',
      orderBy: 'updated_at DESC',
    );
    final mapped = rows.map(_mapRow).toList();
    if (tagId == null) return mapped;
    return mapped.where((snippet) => snippet.tagIds.contains(tagId)).toList();
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
        'tag_ids': jsonEncode(snippet.tagIds),
        'source': snippet.source,
        'pinned': snippet.pinned ? 1 : 0,
        'parameters':
            jsonEncode(snippet.parameters.map((p) => p.toJson()).toList()),
        'version': snippet.version,
        'created_at': snippet.createdAt.toIso8601String(),
        'updated_at': snippet.updatedAt.toIso8601String(),
        'deleted_at': snippet.deletedAt?.toIso8601String(),
        'conflict_of': snippet.conflictOf,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Snippet _mapRow(Map<String, Object?> r) {
    return Snippet(
      id: r['id'] as String,
      title: (r['title'] as String?) ?? '',
      body: (r['body'] as String?) ?? '',
      tagIds: _decodeList(r['tag_ids'] as String?),
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
    final rows = await db.query(
      'snippets',
      where: '(deleted_at IS NULL OR deleted_at = \'\')',
    );
    final counts = <String?, int>{};
    for (final row in rows) {
      final tagIds = _decodeList(row['tag_ids'] as String?);
      for (final tagId in tagIds) {
        counts[tagId] = (counts[tagId] ?? 0) + 1;
      }
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
