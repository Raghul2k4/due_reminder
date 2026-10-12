import 'package:flutter_test/flutter_test.dart';
import 'package:life_reminder/core/extensions/date_extensions.dart';

void main() {
  final ref = DateTime(2026, 10, 9, 10, 0); // Friday Oct 9, 2026

  group('DateTimeExtensions Tests', () {
    test('Same day returns Today', () {
      final dt = DateTime(2026, 10, 9, 15, 30);
      expect(dt.toRelativeString(reference: ref), equals('Today'));
    });

    test('Tomorrow returns Tomorrow', () {
      final dt = DateTime(2026, 10, 10, 8, 0);
      expect(dt.toRelativeString(reference: ref), equals('Tomorrow'));
    });

    test('Yesterday returns Yesterday', () {
      final dt = DateTime(2026, 10, 8, 20, 0);
      expect(dt.toRelativeString(reference: ref), equals('Yesterday'));
    });

    test('In 3 days returns in 3 days', () {
      final dt = DateTime(2026, 10, 12, 10, 0);
      expect(dt.toRelativeString(reference: ref), equals('in 3 days'));
    });

    test('2 days ago returns 2 days ago', () {
      final dt = DateTime(2026, 10, 7, 10, 0);
      expect(dt.toRelativeString(reference: ref), equals('2 days ago'));
    });
  });
}
