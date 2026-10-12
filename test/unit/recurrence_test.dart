import 'package:flutter_test/flutter_test.dart';
import 'package:life_reminder/core/utils/recurrence.dart';
import 'package:life_reminder/data/models/reminder_enums.dart';

void main() {
  group('Recurrence Engine - §9.3 Table Tests', () {
    test('31 Jan 2026 Monthly -> 28 Feb 2026', () {
      final anchor = DateTime(2026, 1, 31);
      final result = computeNextDueDate(
        anchor: anchor,
        from: anchor,
        type: RepeatType.monthly,
      );
      expect(result, DateTime(2026, 2, 28));
    });

    test('31 Jan 2026 Monthly x2 (custom 2 months) -> 31 Mar 2026', () {
      final anchor = DateTime(2026, 1, 31);
      final result = computeNextDueDate(
        anchor: anchor,
        from: anchor,
        type: RepeatType.custom,
        interval: 2,
        unit: RepeatUnit.months,
      );
      expect(result, DateTime(2026, 3, 31));
    });

    test('31 Dec 2026 Monthly -> 31 Jan 2027', () {
      final anchor = DateTime(2026, 12, 31);
      final result = computeNextDueDate(
        anchor: anchor,
        from: anchor,
        type: RepeatType.monthly,
      );
      expect(result, DateTime(2027, 1, 31));
    });

    test('29 Feb 2024 Yearly -> 28 Feb 2025', () {
      final anchor = DateTime(2024, 2, 29);
      final result = computeNextDueDate(
        anchor: anchor,
        from: anchor,
        type: RepeatType.yearly,
      );
      expect(result, DateTime(2025, 2, 28));
    });

    test('29 Feb 2024 Yearly x2 (custom 2 years) -> 28 Feb 2026', () {
      final anchor = DateTime(2024, 2, 29);
      final result = computeNextDueDate(
        anchor: anchor,
        from: anchor,
        type: RepeatType.custom,
        interval: 2,
        unit: RepeatUnit.years,
      );
      expect(result, DateTime(2026, 2, 28));
    });

    test('31 Aug 2026 Every 6 months -> 28 Feb 2027', () {
      final anchor = DateTime(2026, 8, 31);
      final result = computeNextDueDate(
        anchor: anchor,
        from: anchor,
        type: RepeatType.custom,
        interval: 6,
        unit: RepeatUnit.months,
      );
      expect(result, DateTime(2027, 2, 28));
    });

    test('31 Oct 2026 Quarterly -> 31 Jan 2027', () {
      final anchor = DateTime(2026, 10, 31);
      final result = computeNextDueDate(
        anchor: anchor,
        from: anchor,
        type: RepeatType.custom,
        interval: 3,
        unit: RepeatUnit.months,
      );
      expect(result, DateTime(2027, 1, 31));
    });

    test('30 Nov 2026 Quarterly -> 28 Feb 2027', () {
      final anchor = DateTime(2026, 11, 30);
      final result = computeNextDueDate(
        anchor: anchor,
        from: anchor,
        type: RepeatType.custom,
        interval: 3,
        unit: RepeatUnit.months,
      );
      expect(result, DateTime(2027, 2, 28));
    });

    test('30 Apr 2026 Monthly -> 30 May 2026', () {
      final anchor = DateTime(2026, 4, 30);
      final result = computeNextDueDate(
        anchor: anchor,
        from: anchor,
        type: RepeatType.monthly,
      );
      expect(result, DateTime(2026, 5, 30));
    });

    test('15 Jan 2026 Every 2 weeks -> 29 Jan 2026', () {
      final anchor = DateTime(2026, 1, 15);
      final result = computeNextDueDate(
        anchor: anchor,
        from: anchor,
        type: RepeatType.custom,
        interval: 2,
        unit: RepeatUnit.weeks,
      );
      expect(result, DateTime(2026, 1, 29));
    });
  });

  group('Recurrence Engine - Catch-up Across Multiple Cycles', () {
    test('Daily reminder neglected for 5 days advances past "from"', () {
      final anchor = DateTime(2026, 10, 1);
      final from = DateTime(2026, 10, 6, 12, 0);
      final result = computeNextDueDate(
        anchor: anchor,
        from: from,
        type: RepeatType.daily,
      );
      expect(result, DateTime(2026, 10, 7));
    });

    test('Monthly reminder neglected for 3 months advances past "from"', () {
      final anchor = DateTime(2026, 1, 15);
      final from = DateTime(2026, 4, 20);
      final result = computeNextDueDate(
        anchor: anchor,
        from: from,
        type: RepeatType.monthly,
      );
      expect(result, DateTime(2026, 5, 15));
    });
  });

  group('Recurrence Engine - All Repeat Types', () {
    test('RepeatType.none returns anchor', () {
      final anchor = DateTime(2026, 10, 9);
      final result = computeNextDueDate(
        anchor: anchor,
        from: DateTime(2026, 10, 10),
        type: RepeatType.none,
      );
      expect(result, anchor);
    });

    test('RepeatType.daily adds 1 day', () {
      final anchor = DateTime(2026, 10, 9);
      final result = computeNextDueDate(
        anchor: anchor,
        from: anchor,
        type: RepeatType.daily,
      );
      expect(result, DateTime(2026, 10, 10));
    });

    test('RepeatType.weekly adds 7 days', () {
      final anchor = DateTime(2026, 10, 9); // Friday
      final result = computeNextDueDate(
        anchor: anchor,
        from: anchor,
        type: RepeatType.weekly,
      );
      expect(result, DateTime(2026, 10, 16));
    });
  });
}
