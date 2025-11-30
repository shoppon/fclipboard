import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class LocalDb {
  LocalDb._();

  static final LocalDb instance = LocalDb._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await _dbPath();
    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS categories(
            id TEXT PRIMARY KEY,
            name TEXT,
            color TEXT,
            version INTEGER,
            updated_at TEXT,
            user_id TEXT
          );
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS entries(
            id TEXT PRIMARY KEY,
            title TEXT,
            body TEXT,
            tags TEXT,
            source TEXT,
            pinned INTEGER,
            parameters TEXT,
            version INTEGER,
            created_at TEXT,
            updated_at TEXT,
            deleted_at TEXT,
            conflict_of TEXT,
            category_id TEXT
          );
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS sync_ops(
            op_id INTEGER PRIMARY KEY AUTOINCREMENT,
            entity_type TEXT,
            entity_id TEXT,
            op TEXT,
            payload TEXT,
            created_at TEXT
          );
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS metadata(
            key TEXT PRIMARY KEY,
            value TEXT
          );
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // idempotent column add
        await db.execute('ALTER TABLE entries ADD COLUMN IF NOT EXISTS parameters TEXT');
      },
    );
  }

  Future<String> _dbPath() async {
    if (kIsWeb) {
      return 'fclipboard.db';
    }
    final dir = await getApplicationSupportDirectory();
    return p.join(dir.path, 'fclipboard.db');
  }
}

String encodeJson(Object? data) => jsonEncode(data);
T decodeJson<T>(String? data, T fallback) {
  if (data == null) return fallback;
  try {
    return jsonDecode(data) as T;
  } catch (_) {
    return fallback;
  }
}
