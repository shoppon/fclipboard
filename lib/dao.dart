import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:fclipboard/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yaml/yaml.dart';

import 'model.dart' as m;

Future<String> getDatabasePath() async {
  if (isMobile()) {
    final directory = await getApplicationDocumentsDirectory();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final path = join(directory.path, 'fclipboard.db');
    return path;
  } else if (kIsWeb) {
    return "fclipboard.db";
  } else {
    return join(await databaseFactory.getDatabasesPath(), 'fclipboard.db');
  }
}

void createCategoryTable(Database db) {
  db.execute('''
    CREATE TABLE category(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uuid TEXT,
      name TEXT NOT NULL UNIQUE,
      icon TEXT NOT NULL,
      is_private BOOLEAN DEFAULT FALSE
    )
  ''');
}

void createEntryTable(Database db) {
  db.execute('''
    CREATE TABLE entry(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uuid TEXT,
      title TEXT NOT NULL UNIQUE,
      subtitle TEXT NOT NULL,
      counter INTEGER NOT NULL,
      version INTEGER DEFAULT 0,
      category_id INTEGER NOT NULL,
      FOREIGN KEY (category_id) REFERENCES category(id)
    )
  ''');
}

void createParamTable(db) {
  db.execute('''
    CREATE TABLE param(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT,
      required BOOLEAN DEFAULT FALSE,
      initial TEXT,
      entry_id NOT NULL,
      FOREIGN KEY (entry_id) REFERENCES entry(id)
    )
  ''');
}

void version1to2(Database db) {
  // make title column UNIQUE
  db.execute('''
    CREATE UNIQUE INDEX idx_entry_title ON entry(title)
  ''');
  db.execute('''
    CREATE UNIQUE INDEX idx_category_name ON category(name)
  ''');
}

void version2to3(Database db) {
  db.execute('''
    ALTER TABLE category ADD COLUMN is_private BOOLEAN DEFAULT FALSE
  ''');
  createParamTable(db);
}

void version3to4(Database db) {
  // add uuid column for entry
  db.execute('''
    ALTER TABLE entry ADD COLUMN uuid TEXT
  ''');
}

void version4to5(Database db) {
  db.execute('''
    ALTER TABLE category ADD COLUMN uuid TEXT
  ''');
}

void version5to6(Database db) {
  // add uuid column for param
  db.execute('''
    ALTER TABLE entry ADD COLUMN version INTEGER DEFAULT 0
  ''');
}

class DBHelper {
  Future<Database> get database async {
    return openDatabase(
      await getDatabasePath(),
      onCreate: (db, version) {
        createCategoryTable(db);
        createEntryTable(db);
        createParamTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) {
        final versions = {
          1: version1to2,
          2: version2to3,
          3: version3to4,
          4: version4to5,
          5: version5to6,
        };
        for (var i = oldVersion; i < newVersion; i++) {
          versions[i]!(db);
        }
      },
      version: 6,
    );
  }

  Future<int> insertCategory(m.Category category) async {
    final Database db = await database;
    final id = await db.insert(
      'category',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  Future<int> insertEntry(m.Entry entry) async {
    final Database db = await database;
    final int id = await db.insert(
      'entry',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // delete existing parameters
    await db.delete(
      'param',
      where: "entry_id = ?",
      whereArgs: [id],
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

  Future<List<m.Category>> categories() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('category');
    return List.generate(maps.length, (i) {
      return m.Category(
        name: maps[i]['name'],
        icon: maps[i]['icon'],
        id: maps[i]['id'],
        uuid: maps[i]['uuid']?.toString() ?? '',
        isPrivate: maps[i]['is_private'] == 1,
      );
    });
  }

  Future<List<m.Entry>> entries(
      {List<String>? categories, String? title}) async {
    final Database db = await database;
    List<Map<String, Object?>> results;
    var query = '''
      SELECT entry.id, entry.uuid, entry.title, entry.subtitle, entry.counter, entry.version, entry.category_id, category.name as c_name, category.icon, param.id as p_id, param.name as p_name, param.initial, param.description, param.required
      FROM entry
      INNER JOIN category ON entry.category_id = category.id
      LEFT JOIN param ON entry.id = param.entry_id
    ''';
    if (title != null) {
      query += '''
        WHERE entry.title = '$title'
      ''';
    }
    if (categories != null) {
      List<String> cats = [];
      for (var c in categories) {
        cats.add("'$c'");
      }
      query += '''
        WHERE category.name IN (${cats.join(", ")})
      ''';
    }
    results = await db.rawQuery(query);
    List<m.Entry> entries = [];
    for (var r in results) {
      // find existing entry
      m.Entry? entry = entries.firstWhereOrNull((e) => e.title == r['title']);
      if (entry != null) {
        entry.parameters.add(m.Param(
          id: r['p_id'] as int,
          name: r['p_name'].toString(),
          initial: r['initial'].toString(),
          description: r['description'].toString(),
          required: r['required'] == 1,
        ));
      } else {
        entries.add(m.Entry(
          id: r['id'] as int,
          uuid: r['uuid']?.toString() ?? '',
          title: r['title'].toString(),
          subtitle: r['subtitle'].toString(),
          counter: r['counter'] as int,
          version: r['version'] as int,
          categoryId: r['category_id'] as int,
          categoryName: r['c_name'].toString(),
          icon: r['icon'].toString(),
          parameters: [],
        ));
        if (r['p_name'] != null) {
          entries.last.parameters.add(m.Param(
            id: r['p_id'] as int,
            name: r['p_name'].toString(),
            initial: r['initial'].toString(),
            description: r['description'].toString(),
            required: r['required'] == 1,
          ));
        }
      }
    }
    return entries;
  }

  Future<void> deleteEntry(String title) async {
    final Database db = await database;
    await db.delete(
      'param',
      where: "entry_id IN (SELECT id FROM entry WHERE title = ?)",
      whereArgs: [title],
    );
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

  Future<m.Category?> getCategoryByName(String name) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'category',
      where: "name = ?",
      whereArgs: [name],
    );
    if (maps.isEmpty) {
      return null;
    }
    return m.Category(
      name: maps[0]['name'],
      icon: maps[0]['icon'],
      id: maps[0]['id'],
      isPrivate: maps[0]['is_private'] == 1,
    );
  }

  Future<void> deleteAll() async {
    final Database db = await database;
    await db.delete('category');
    await db.delete('entry');
    // drop databases
    await deleteDatabase(await getDatabasePath());
  }

  Future<void> exportToFile(String filepath) async {
    final allEntries = await entries();
    final allCategories = await categories();
    final file = File(filepath);
    final sink = file.openWrite();
    // write with yaml format
    sink.writeln('---');
    sink.writeln('categories:');
    for (var c in allCategories) {
      if (c.isPrivate) {
        continue;
      }
      sink.writeln('  - name: "${c.name}"');
      sink.writeln('    icon: "${c.icon}"');
    }
    sink.writeln('entries:');
    for (var e in allEntries) {
      final category = allCategories.firstWhere((c) => c.id == e.categoryId);
      if (category.isPrivate) {
        continue;
      }
      sink.writeln('  - uuid: "${e.uuid}"');
      sink.writeln('  - title: "${e.title}"');
      // subtitle may contain special characters and has multiple lines
      sink.writeln('    subtitle: |-');
      for (var line in e.subtitle.split('\n')) {
        sink.writeln('      $line');
      }
      sink.writeln('    counter: ${e.counter}');
      sink.writeln('    version: ${e.version}');
      sink.writeln('    category: "${e.categoryName}"');
      sink.writeln('    parameters:');
      for (var p in e.parameters) {
        sink.writeln('      - name: "${p.name}"');
        sink.writeln('        initial: "${p.initial}"');
        sink.writeln('        description: "${p.description}"');
        sink.writeln('        required: ${p.required}');
      }
    }
    await sink.flush();
    await sink.close();
  }

  Future<void> importFromFile(String filepath) async {
    // parse yaml file
    final file = File(filepath);
    final content = await file.readAsString();
    final source = loadYaml(content);
    await importFromYaml(source);
  }

  Future<void> importFromYaml(dynamic source) async {
    // get current categories and entries
    final cgs = await categories();
    final curEntries = await entries();
    final categoryIds = cgs.fold({}, (map, cgs) => map..[cgs.name] = cgs.id);

    // insert categories
    for (var c in source['categories']) {
      await insertCategory(m.Category(
        id: categoryIds[c['name']] ?? 0,
        name: c['name'],
        icon: c['icon'],
        isPrivate: c['isPrivate'] ?? false,
      ));
    }
    // insert entries
    for (var e in source['entries']) {
      // find existing entry
      final existing =
          curEntries.firstWhereOrNull((ce) => ce.title == e['title']);
      final params = <m.Param>[];
      for (var p in e['parameters'] ?? []) {
        final param =
            existing?.parameters.firstWhereOrNull((pm) => pm.name == p['name']);
        params.add(m.Param(
          id: param == null ? 0 : param.id,
          name: p['name'],
          initial: p['initial'] ?? '',
          description: p['description'] ?? '',
          required: p['required'] ?? false,
          entryId: existing == null ? 0 : existing.id,
        ));
      }
      final entry = m.Entry(
        id: existing == null ? 0 : existing.id,
        uuid: existing == null ? '' : existing.uuid,
        title: e['title'],
        subtitle: e['subtitle'],
        counter: e['counter'],
        version: e['version'],
        categoryId: categoryIds[e['category']] as int,
        parameters: params,
      );
      await insertEntry(entry);
    }
  }

  Future<void> importEntry(m.Entry entry) async {
    // set entry id
    final ets = await entries(title: entry.title);
    if (ets.isNotEmpty) {
      entry.id = ets.first.id;
    } else {
      entry.id = 0;
    }
    // add category if not exists
    final category = await getCategoryByName(entry.categoryName);
    if (category == null) {
      final id = await insertCategory(
          m.Category(name: entry.categoryName, icon: '😆'));
      entry.categoryId = id;
    } else {
      entry.categoryId = category.id;
    }
    // insert entry
    await insertEntry(entry);
  }
}
