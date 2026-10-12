import 'package:flutter_test/flutter_test.dart';
import 'package:life_reminder/core/utils/subscription_recurrence.dart';
import 'package:life_reminder/data/models/subscription_enums.dart';

void main() {
  group('Subscription renewal advance (§6.4 month-end safety)', () {
    test('Weekly advances 7 days', () {
      final anchor = DateTime(2026, 10, 9);
      final result = computeNextRenewalDate(anchor: anchor, from: anchor, cycle: BillingCycle.weekly);
      expect(result, DateTime(2026, 10, 16));
    });

    test('Monthly on 31 Jan clamps to 28 Feb 2026', () {
      final anchor = DateTime(2026, 1, 31);
      final result = computeNextRenewalDate(anchor: anchor, from: anchor, cycle: BillingCycle.monthly);
      expect(result, DateTime(2026, 2, 28));
    });

    test('Monthly on 31 Jan clamps to 28 Feb in a leap year (2028)', () {
      final anchor = DateTime(2028, 1, 31);
      final result = computeNextRenewalDate(anchor: anchor, from: anchor, cycle: BillingCycle.monthly);
      expect(result, DateTime(2028, 2, 29));
    });

    test('Quarterly on 31 Aug 2026 -> 30 Nov 2026 -> 28 Feb 2027', () {
      final anchor = DateTime(2026, 8, 31);
      final first = computeNextRenewalDate(anchor: anchor, from: anchor, cycle: BillingCycle.quarterly);
      expect(first, DateTime(2026, 11, 30));
      final second = computeNextRenewalDate(anchor: first, from: first, cycle: BillingCycle.quarterly);
      expect(second, DateTime(2027, 2, 28));
    });

    test('Yearly on 29 Feb 2024 -> 28 Feb 2025 (leap clamp)', () {
      final anchor = DateTime(2024, 2, 29);
      final result = computeNextRenewalDate(anchor: anchor, from: anchor, cycle: BillingCycle.yearly);
      expect(result, DateTime(2025, 2, 28));
    });

    test('Yearly on 29 Feb 2024 stays clamped to 28 Feb through 2028 (no re-expansion)', () {
      // Step-from-previous keeps the clamped day; once clamped to 28 it stays 28.
      // This matches the documented drift-free behaviour (§9.3: 29 Feb + 2y = 28 Feb 2026).
      final anchor = DateTime(2024, 2, 29);
      var current = anchor;
      for (int i = 0; i < 4; i++) {
        current = computeNextRenewalDate(anchor: current, from: current, cycle: BillingCycle.yearly);
      }
      expect(current, DateTime(2028, 2, 28));
    });

    test('Anchor after "from" is returned unchanged', () {
      final anchor = DateTime(2026, 12, 1);
      final result = computeNextRenewalDate(anchor: anchor, from: DateTime(2026, 1, 1), cycle: BillingCycle.monthly);
      expect(result, anchor);
    });

    test('Neglected monthly catches up strictly past "from"', () {
      final anchor = DateTime(2026, 1, 15);
      final from = DateTime(2026, 4, 20);
      final result = computeNextRenewalDate(anchor: anchor, from: from, cycle: BillingCycle.monthly);
      expect(result, DateTime(2026, 5, 15));
      expect(result.isAfter(from), isTrue);
    });
  });

  group('upcomingRenewals preview', () {
    test('Returns the requested count of future renewals', () {
      final anchor = DateTime(2026, 1, 31);
      final result = upcomingRenewals(anchor: anchor, from: anchor, cycle: BillingCycle.monthly, count: 3);
      expect(result, [
        DateTime(2026, 2, 28),
        DateTime(2026, 3, 28),
        DateTime(2026, 4, 28),
      ]);
    });
  });

  group('Spending normalisation (§2)', () {
    test('Monthly equivalent for weekly uses 52/12', () {
      // 12.00/week => 52.00/year => 4.333.../month
      expect(monthlyEquivalent(12, BillingCycle.weekly), closeTo(52, 0.0001));
    });

    test('Monthly equivalent: monthly = price, quarterly = /3, yearly = /12', () {
      expect(monthlyEquivalent(10, BillingCycle.monthly), 10);
      expect(monthlyEquivalent(30, BillingCycle.quarterly), 10);
      expect(monthlyEquivalent(120, BillingCycle.yearly), 10);
    });

    test('Yearly equivalent: weekly*52, monthly*12, quarterly*4, yearly = price', () {
      expect(yearlyEquivalent(10, BillingCycle.weekly), 520);
      expect(yearlyEquivalent(10, BillingCycle.monthly), 120);
      expect(yearlyEquivalent(10, BillingCycle.quarterly), 40);
      expect(yearlyEquivalent(100, BillingCycle.yearly), 100);
    });
  });
}
