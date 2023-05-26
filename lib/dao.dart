import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yaml/yaml.dart';

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
        createParamTable(db);
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
          createParamTable(db);
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

  Future<List<Entry>> entries({String? category, String? title}) async {
    final Database db = await database;
    List<Map<String, Object?>> results;
    var query = '''
      SELECT entry.id, entry.title, entry.subtitle, entry.counter, entry.category_id, category.name as c_name, category.icon, param.id as p_id, param.name as p_name, param.initial, param.description, param.required
      FROM entry
      INNER JOIN category ON entry.category_id = category.id
      LEFT JOIN param ON entry.id = param.entry_id
    ''';
    final params = [];
    if (title != null) {
      query += '''
        WHERE entry.id = ?
      ''';
      params.add(title);
    }
    if (category != null) {
      query += '''
        WHERE category.name = ?
      ''';
      params.add(category);
    }
    results = await db.rawQuery(query, params);
    List<Entry> entries = [];
    for (var r in results) {
      // find existing entry
      Entry? entry = entries.firstWhereOrNull((e) => e.title == r['title']);
      if (entry != null) {
        entry.parameters.add(Param(
          id: r['p_id'] as int,
          name: r['p_name'].toString(),
          initial: r['initial'].toString(),
          description: r['description'].toString(),
          required: r['required'] == 1,
        ));
      } else {
        entries.add(Entry(
          id: r['id'] as int,
          title: r['title'].toString(),
          subtitle: r['subtitle'].toString(),
          counter: r['counter'] as int,
          categoryId: r['category_id'] as int,
          categoryName: r['c_name'].toString(),
          icon: r['icon'].toString(),
          parameters: [],
        ));
        if (r['p_name'] != null) {
          entries.last.parameters.add(Param(
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

  Future<void> deleteAll() async {
    final Database db = await database;
    await db.delete('category');
    await db.delete('entry');
    // drop databases
    await deleteDatabase(await getDatabasePath());
  }

  Future<void> export(String filepath) async {
    final allEntries = await entries();
    final allCategories = await categories();
    final file = File(filepath);
    final sink = file.openWrite();
    // write with yaml format
    sink.writeln('---');
    sink.writeln('categories:');
    for (var c in allCategories) {
      sink.writeln('  - name: "${c.name}"');
      sink.writeln('    icon: "${c.icon}"');
    }
    sink.writeln('entries:');
    for (var e in allEntries) {
      sink.writeln('  - title: "${e.title}"');
      // subtitle may contain special characters and has multiple lines
      sink.writeln('    subtitle: |-');
      for (var line in e.subtitle.split('\n')) {
        sink.writeln('      $line');
      }
      sink.writeln('    counter: ${e.counter}');
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

  Future<void> import(String filepath) async {
    // parse yaml file
    final file = File(filepath);
    final content = await file.readAsString();
    final source = loadYaml(content);

    // get current categories and entries
    final cgs = await categories();
    final curEntries = await entries();
    final categoryIds = cgs.fold({}, (map, cgs) => map..[cgs.name] = cgs.id);

    // insert categories
    for (var c in source['categories']) {
      await insertCategory(Category(
        id: categoryIds[c['name']] ?? 0,
        name: c['name'],
        icon: c['icon'],
      ));
    }
    // insert entries
    for (var e in source['entries']) {
      // find existing entry
      final existing =
          curEntries.firstWhereOrNull((ce) => ce.title == e['title']);
      final params = <Param>[];
      for (var p in e['parameters'] ?? []) {
        final param =
            existing?.parameters.firstWhereOrNull((pm) => pm.name == p['name']);
        params.add(Param(
          id: param == null ? 0 : param.id,
          name: p['name'],
          initial: p['initial'] ?? '',
          description: p['description'] ?? '',
          required: p['required'] ?? false,
          entryId: existing == null ? 0 : existing.id,
        ));
      }
      final entry = Entry(
        id: existing == null ? 0 : existing.id,
        title: e['title'],
        subtitle: e['subtitle'],
        counter: e['counter'],
        categoryId: categoryIds[e['category']] as int,
        parameters: params,
      );
      await insertEntry(entry);
    }
  }
}
