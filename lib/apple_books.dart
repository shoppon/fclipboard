import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fclipboard/dao.dart';
import 'package:fclipboard/model.dart';
import 'package:sqflite/sqflite.dart';

Future<List<Book>> readBooks(List<PlatformFile> files) async {
  if (files.isEmpty) {
    return [];
  }

  final sqliteFile =
      files.firstWhereOrNull((e) => e.path!.startsWith('BKLibrary'));
  if (sqliteFile == null) {
    return [];
  }
  Database db = await openDatabase(
    sqliteFile.path!,
    readOnly: true,
    singleInstance: false,
  );
  final List<Map<String, dynamic>> books =
      await db.rawQuery('SELECT * FROM ZBKLIBRARYASSET');
  await db.close();
  return List.generate(books.length, (i) {
    return Book(
      uuid: books[i]['ZASSETID'] ?? '',
      title: books[i]['ZTITLE'] ?? '',
      author: books[i]['ZAUTHOR'] ?? '',
    );
  });
}

Future<List<Annotation>> readAnnotations(List<PlatformFile> files) async {
  if (files.isEmpty) {
    return [];
  }

  final sqliteFile =
      files.firstWhereOrNull((e) => e.path!.startsWith('AEAnnotation'));
  if (sqliteFile == null) {
    return [];
  }
  Database db = await openDatabase(
    sqliteFile.path!,
    readOnly: true,
    singleInstance: false,
  );
  final List<Map<String, dynamic>> notes =
      await db.rawQuery('SELECT * FROM ZAEANNOTATION');
  await db.close();
  return List.generate(notes.length, (i) {
    return Annotation(
      uuid: notes[i]['ZANNOTATIONUUID'] ?? '',
      bookId: notes[i]['ZANNOTATIONASSETID'] ?? '',
      location: notes[i]['ZANNOTATIONLOCATION'] ?? '',
      selected: notes[i]['ZANNOTATIONSELECTEDTEXT'] ?? '',
      highlight: notes[i]['ZANNOTATIONNOTE'] ?? '',
      color: notes[i]['ZANNOTATIONSTYLE'] ?? 0,
      deleted: notes[i]['ZANNOTATIONDELETED'] ?? 1,
      createdAt: notes[i]['ZANNOTATIONCREATIONDATE'] ?? 0.0,
    );
  });
}

Future<void> importAppleBooks(List<PlatformFile> files) async {
  final books = await readBooks(files);
  final annotations = await readAnnotations(files);
  final helper = DBHelper();
  await helper.batchInsertBooks(books);
  await helper.batchInsertAnnotations(annotations);
}
