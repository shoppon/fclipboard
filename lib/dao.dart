import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import 'model.dart';

Future<String> getDatabasePath() async {
  if (Platform.isIOS || Platform.isAndroid) {
    final directory = await getApplicationDocumentsDirectory();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final path = join(directory.path, 'fclipboard.db');
    return path;
  } else {
    return join(await databaseFactory.getDatabasesPath(), 'fclipboard.db');
  }
}

void createEntryTable(db) {
  db.execute('''
    CREATE TABLE param(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      initial TEXT,
      entry_id NOT NULL,
      FOREIGN KEY (entry_id) REFERENCES entry(id)
    )
  ''');
}

class DBHelper {
  Future<Database> get database async {
    return openDatabase(
      await getDatabasePath(),
      onCreate: (db, version) {
        db.execute('''
          CREATE TABLE category(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            icon TEXT NOT NULL
          )
        ''');
        db.execute('''
          CREATE TABLE entry(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL UNIQUE,
            subtitle TEXT NOT NULL,
            counter INTEGER NOT NULL,
            category_id NOT NULL,
            FOREIGN KEY (category_id) REFERENCES category(id)
          )
        ''');
        createEntryTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) {
        if (oldVersion == 1) {
          // make title column UNIQUE
          db.execute('''
            CREATE UNIQUE INDEX idx_entry_title ON entry(title)
          ''');
          db.execute('''
            CREATE UNIQUE INDEX idx_category_name ON category(name)
          ''');
        }
        if (oldVersion == 2) {
          createEntryTable(db);
        }
      },
      version: 3,
    );
  }

  Future<int> insertCategory(Category category) async {
    final Database db = await database;
    final id = await db.insert(
      'category',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  Future<int> insertEntry(Entry entry) async {
    final Database db = await database;
    final int id = await db.insert(
      'entry',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (entry.parameters.isNotEmpty) {
      for (var p in entry.parameters) {
        await db.insert(
          'param',
          p.toMap(id),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
    return id;
  }

  Future<List<Category>> categories() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('category');
    return List.generate(maps.length, (i) {
      return Category(
        name: maps[i]['name'],
        icon: maps[i]['icon'],
        id: maps[i]['id'],
      );
    });
  }

  Future<List<Entry>> entries(String? category) async {
    final Database db = await database;
    List<Map<String, Object?>> results;
    if (category == null || category == 'all') {
      results = await db.rawQuery('''
      SELECT entry.title, entry.subtitle, entry.counter, entry.category_id, category.name as c_name, category.icon, param.name as p_name, param.initial
      FROM entry
      INNER JOIN category ON entry.category_id = category.id
      LEFT JOIN param ON entry.id = param.entry_id
    ''');
    } else {
      results = await db.rawQuery('''
      SELECT entry.title, entry.subtitle, entry.counter, entry.category_id, category.name, category.icon
      FROM entry
      INNER JOIN category ON entry.category_id = category.id
      WHERE category.name = ?
    ''', [category]);
    }
    List<Entry> entries = [];
    for (var r in results) {
      // find existing entry
      Entry? entry = entries.firstWhereOrNull((e) => e.title == r['title']);
      if (entry != null) {
        entry.parameters.add(Param(
          name: r['p_name'].toString(),
          initial: r['initial'].toString(),
        ));
      } else {
        entries.add(Entry(
          title: r['title'].toString(),
          subtitle: r['subtitle'].toString(),
          counter: r['counter'] as int,
          categoryId: r['category_id'] as int,
          icon: r['icon'].toString(),
          parameters: [],
        ));
        if (r['p_name'] != null) {
          entries.last.parameters.add(Param(
            name: r['p_name'].toString(),
            initial: r['initial'].toString(),
          ));
        }
      }
    }
    return entries;
  }

  Future<void> deleteEntry(String title) async {
    final Database db = await database;
    await db.delete(
      'entry',
      where: "title = ?",
      whereArgs: [title],
    );
  }

  Future<void> deleteCategory(String category) async {
    final Database db = await database;
    await db.delete(
      'category',
      where: "name = ?",
      whereArgs: [category],
    );
  }

  Future<void> incEntryCounter(String title) async {
    final Database db = await database;
    await db.rawUpdate('''
      UPDATE entry
      SET counter = counter + 1
      WHERE title = ?
    ''', [title]);
  }

  Future<void> deleteAll() async {
    final Database db = await database;
    await db.delete('category');
    await db.delete('entry');
    // drop databases
    await deleteDatabase(await getDatabasePath());
  }
}
