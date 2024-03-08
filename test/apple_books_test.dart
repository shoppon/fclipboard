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

  test('calc time', () {
    final baseTime = DateTime.parse("2001-01-01 00:00:00");
    final resultTime = baseTime.add(const Duration(seconds: 731553135));

    expect("2024-03-08 01:12:15.000", resultTime.toString());
  });
}
