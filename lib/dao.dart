import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import 'model.dart';

Future<String> getDatabasePath() async {
  if (Platform.isIOS) {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'fclipboard.db');
    return path;
  } else {
    return join(await databaseFactory.getDatabasesPath(), 'fclipboard.db');
  }
}

class DBHelper {
  Future<Database> get database async {
    return openDatabase(
      await getDatabasePath(),
      onCreate: (db, version) {
        db.execute(
          "CREATE TABLE category(id INTEGER PRIMARY KEY, name TEXT, icon TEXT, conf TEXT)",
        );
        db.execute(
          "CREATE TABLE entry(id INTEGER PRIMARY KEY, title TEXT, subtitle TEXT, category TEXT)",
        );
        final categories = [
          'ceph',
          'es',
          'git',
          'golang',
          'iscsi',
          'k8s',
          'kubernetes',
          'linux',
          'mysql',
          'openstack',
          'symbol',
          'vscode'
        ];
        for (var c in categories) {
          db.execute(
            "INSERT INTO category(name, icon, conf) VALUES('$c', 'assets/images/$c.png', 'assets/commands/$c.yaml')",
          );
        }
      },
      version: 1,
    );
  }

  Future<void> insertCategory(Category category) async {
    final Database db = await database;
    await db.insert(
      'category',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertEntry(Entry entry) async {
    final Database db = await database;
    await db.insert(
      'entry',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Category>> categories() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('category');
    return List.generate(maps.length, (i) {
      return Category(
        name: maps[i]['name'],
        icon: maps[i]['icon'],
        conf: maps[i]['conf'],
      );
    });
  }

  Future<List<Entry>> entries(String? category) async {
    final Database db = await database;
    var query = db.query('entry');
    if (category != null) {
      query = db.query('entry', where: 'category = ?', whereArgs: [category]);
    }
    final List<Map<String, dynamic>> maps = await query;
    return List.generate(maps.length, (i) {
      return Entry(
        title: maps[i]['title'],
        subtitle: maps[i]['subtitle'],
        category: maps[i]['category'],
      );
    });
  }

  Future<void> deleteEntry(String title) async {
    final Database db = await database;
    await db.delete(
      'entry',
      where: "title = ?",
      whereArgs: [title],
    );
  }

  void deleteAll() async {
    final Database db = await database;
    await db.delete('category');
    await db.delete('entry');
  }
}
