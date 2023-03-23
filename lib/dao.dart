import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'model.dart';

class DBHelper {
  Future<Database> get database async {
    return openDatabase(
      join(await getDatabasesPath(), 'fclipboard.db'),
      onCreate: (db, version) {
        db.execute(
          "CREATE TABLE category(id INTEGER PRIMARY KEY, name TEXT, icon TEXT, conf TEXT)",
        );
        db.execute(
          "CREATE TABLE entry(id INTEGER PRIMARY KEY, title TEXT, subtitle TEXT, category TEXT)",
        );
        db.execute(
          "INSERT INTO category(name, icon, conf) VALUES('default', 'assets/icons/clipboard.png', '')",
        );
        db.execute(
          "INSERT INTO category(name, icon, conf) VALUES('ceph', 'assets/images/ceph.png', 'assets/commands/ceph.yaml')",
        );
        db.execute(
          "INSERT INTO category(name, icon, conf) VALUES('git', 'assets/images/git.png', 'assets/commands/git.yaml')",
        );
        db.execute(
          "INSERT INTO category(name, icon, conf) VALUES('golang', 'assets/images/golang.png', 'assets/commands/golang.yaml')",
        );
        db.execute(
          "INSERT INTO category(name, icon, conf) VALUES('k8s', 'assets/images/kubernetes.png', 'assets/commands/k8s.yaml')",
        );
        db.execute(
          "INSERT INTO category(name, icon, conf) VALUES('linux', 'assets/images/linux.png', 'assets/commands/linux.yaml')",
        );
        db.execute(
          "INSERT INTO category(name, icon, conf) VALUES('mysql', 'assets/images/mysql.png', 'assets/commands/mysql.yaml')",
        );
        db.execute(
          "INSERT INTO category(name, icon, conf) VALUES('openstack', 'assets/images/openstack.png', 'assets/commands/openstack.yaml')",
        );
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

  Future<List<Entry>> entries() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('entry');
    return List.generate(maps.length, (i) {
      return Entry(
        title: maps[i]['title'],
        subtitle: maps[i]['subtitle'],
        category: maps[i]['category'],
      );
    });
  }

  void deleteAll() async {
    final Database db = await database;
    await db.delete('category');
    await db.delete('entry');
  }
}
