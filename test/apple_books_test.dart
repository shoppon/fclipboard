import 'package:test/test.dart';

void main() {
  test('calc time', () {
    final baseTime = DateTime.parse("2001-01-01 00:00:00");
    final resultTime = baseTime.add(const Duration(seconds: 731553135));

    expect("2024-03-08 01:12:15.000", resultTime.toString());
  });
}
