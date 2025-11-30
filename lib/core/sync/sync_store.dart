import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../db/local_db.dart';

class SyncOp {
  SyncOp({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.op,
    required this.payload,
    required this.createdAt,
  });

  final int id;
  final String entityType;
  final String entityId;
  final String op;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
}

class SyncStore {
  SyncStore(this._dbProvider);

  final LocalDb _dbProvider;

  Future<void> enqueue({
    required String entityType,
    required String entityId,
    required String op,
    required Map<String, dynamic> payload,
  }) async {
    final db = await _dbProvider.database;
    await db.insert('sync_ops', {
      'entity_type': entityType,
      'entity_id': entityId,
      'op': op,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<SyncOp>> pending(String entityType) async {
    final db = await _dbProvider.database;
    final rows = await db.query(
      'sync_ops',
      where: 'entity_type = ?',
      whereArgs: [entityType],
      orderBy: 'created_at ASC',
      limit: 200,
    );
    return rows
        .map(
          (r) => SyncOp(
            id: r['op_id'] as int,
            entityType: r['entity_type'] as String,
            entityId: r['entity_id'] as String,
            op: r['op'] as String,
            payload: jsonDecode(r['payload'] as String) as Map<String, dynamic>,
            createdAt: DateTime.tryParse((r['created_at'] as String?) ?? '') ?? DateTime.now(),
          ),
        )
        .toList();
  }

  Future<void> deleteOps(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await _dbProvider.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.delete('sync_ops', where: 'op_id IN ($placeholders)', whereArgs: ids);
  }

  Future<DateTime?> lastSynced(String key) async {
    final db = await _dbProvider.database;
    final rows = await db.query('metadata', where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return DateTime.tryParse((rows.first['value'] as String?) ?? '');
  }

  Future<void> setLastSynced(String key, DateTime value) async {
    final db = await _dbProvider.database;
    await db.insert(
      'metadata',
      {'key': key, 'value': value.toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
