import 'package:fclipboard/apple_books.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  test('read annotations', () async {
    databaseFactory = databaseFactoryFfi;

    final annotations = await readAnnotations();
    expect(annotations.isNotEmpty, true);
  });

  test('read books', () async {
    databaseFactory = databaseFactoryFfi;

    final books = await readBooks();
    expect(books.isNotEmpty, true);
  });
}
