import 'package:flutter_test/flutter_test.dart';
import 'package:life_reminder/core/services/quick_add_parser.dart';
import 'package:life_reminder/data/models/reminder_enums.dart';

void main() {
  final now = DateTime(2026, 10, 9, 10, 0); // Friday Oct 9, 2026

  group('QuickAddParser Tests - §11.1 Table', () {
    test('bike service every 3 months', () {
      final res = QuickAddParser.parse('bike service every 3 months', now: now);
      expect(res.title, equals('Bike service'));
      expect(res.repeatType, equals(RepeatType.custom));
      expect(res.repeatInterval, equals(3));
      expect(res.repeatUnit, equals(RepeatUnit.months));
      expect(res.categoryHintId, equals('cat_vehicle'));
    });

    test('pay rent every month on the 5th', () {
      final res = QuickAddParser.parse('pay rent every month on the 5th', now: now);
      expect(res.title, equals('Pay rent'));
      expect(res.repeatType, equals(RepeatType.monthly));
      expect(res.categoryHintId, equals('cat_finance'));
    });

    test('water plants every 2 days', () {
      final res = QuickAddParser.parse('water plants every 2 days', now: now);
      expect(res.title, equals('Water plants'));
      expect(res.repeatType, equals(RepeatType.custom));
      expect(res.repeatInterval, equals(2));
      expect(res.repeatUnit, equals(RepeatUnit.days));
      expect(res.categoryHintId, equals('cat_home'));
    });

    test('dentist every 6 months', () {
      final res = QuickAddParser.parse('dentist every 6 months', now: now);
      expect(res.title, equals('Dentist'));
      expect(res.repeatType, equals(RepeatType.custom));
      expect(res.repeatInterval, equals(6));
      expect(res.repeatUnit, equals(RepeatUnit.months));
      expect(res.categoryHintId, equals('cat_health'));
    });

    test('call mom every week', () {
      final res = QuickAddParser.parse('call mom every week', now: now);
      expect(res.title, equals('Call mom'));
      expect(res.repeatType, equals(RepeatType.weekly));
    });

    test('passport renewal every year', () {
      final res = QuickAddParser.parse('passport renewal every year', now: now);
      expect(res.title, equals('Passport renewal'));
      expect(res.repeatType, equals(RepeatType.yearly));
      expect(res.categoryHintId, equals('cat_documents'));
    });

    test('insurance tomorrow', () {
      final res = QuickAddParser.parse('insurance tomorrow', now: now);
      expect(res.title, equals('Insurance'));
      expect(res.dueDate, equals(DateTime(2026, 10, 10)));
      expect(res.categoryHintId, equals('cat_finance'));
    });

    test('gym today at 6pm', () {
      final res = QuickAddParser.parse('gym today at 6pm', now: now);
      expect(res.title, equals('Gym'));
      expect(res.dueDate, equals(DateTime(2026, 10, 9)));
      expect(res.dueTime, equals(DateTime(2026, 10, 9, 18, 0)));
      expect(res.categoryHintId, equals('cat_health'));
    });

    test('submit report in 3 days', () {
      final res = QuickAddParser.parse('submit report in 3 days', now: now);
      expect(res.title, equals('Submit report'));
      expect(res.dueDate, equals(DateTime(2026, 10, 12)));
    });

    test('pay bill', () {
      final res = QuickAddParser.parse('pay bill', now: now);
      expect(res.title, equals('Pay bill'));
      expect(res.repeatType, equals(RepeatType.none));
      expect(res.categoryHintId, equals('cat_finance'));
    });
  });
}
