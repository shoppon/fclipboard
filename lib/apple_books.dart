import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:fclipboard/dao.dart';
import 'package:fclipboard/model.dart';
import 'package:sqflite/sqflite.dart';

const String bookDir =
    'Library/Containers/com.apple.iBooksX/Data/Documents/BKLibrary/';
const String annotationDir =
    'Library/Containers/com.apple.iBooksX/Data/Documents/AEAnnotation/';

Future<List<Book>> readBooks() async {
  final homeDir = Platform.environment['HOME'];
  final bookPath = path.join(homeDir!, bookDir);
  List<FileSystemEntity> files = Directory(bookPath).listSync();
  if (files.isEmpty) {
    return [];
  }

  final sqliteFile = files.firstWhere((e) => e.path.endsWith('.sqlite'));
  Database db = await openDatabase(sqliteFile.path);
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

Future<List<Annotation>> readAnnotations() async {
  final homeDir = Platform.environment['HOME'];
  final annotationPath = path.join(homeDir!, annotationDir);
  List<FileSystemEntity> files = Directory(annotationPath).listSync();
  if (files.isEmpty) {
    return [];
  }

  final sqliteFile = files.firstWhere((e) => e.path.endsWith('.sqlite'));
  Database db = await openDatabase(sqliteFile.path);
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

Future<void> importAppleBooks() async {
  final books = await readBooks();
  final annotations = await readAnnotations();
  final helper = DBHelper();
  await helper.batchInsertBooks(books);
  await helper.batchInsertAnnotations(annotations);
}
