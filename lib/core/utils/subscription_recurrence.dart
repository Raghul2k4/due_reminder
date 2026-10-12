import '../../data/models/subscription_enums.dart';
import 'recurrence.dart';

/// Advances a date by exactly one billing cycle.
///
/// Pure function. Month-based cycles use [addMonthsClamped] so month-end and
/// leap-year anchors clamp safely (e.g. 31 Jan + 1 month = 28/29 Feb) instead
/// of overflowing into the following month (§6.4).
DateTime advanceOneCycle(DateTime date, BillingCycle cycle) {
  switch (cycle) {
    case BillingCycle.weekly:
      return date.add(const Duration(days: 7));
    case BillingCycle.monthly:
      return addMonthsClamped(date, 1);
    case BillingCycle.quarterly:
      return addMonthsClamped(date, 3);
    case BillingCycle.yearly:
      return addMonthsClamped(date, 12);
  }
}

/// Returns the next renewal strictly after [from], stepping from the previous
/// candidate so long-neglected subscriptions catch up without drift (§9.2).
DateTime computeNextRenewalDate({
  required DateTime anchor,
  required DateTime from,
  required BillingCycle cycle,
}) {
  if (anchor.isAfter(from)) return anchor;

  var candidate = advanceOneCycle(anchor, cycle);
  while (!candidate.isAfter(from)) {
    candidate = advanceOneCycle(candidate, cycle);
  }
  return candidate;
}

/// The next [count] renewal dates strictly after [from].
List<DateTime> upcomingRenewals({
  required DateTime anchor,
  required DateTime from,
  required BillingCycle cycle,
  int count = 3,
}) {
  final results = <DateTime>[];
  var current = computeNextRenewalDate(anchor: anchor, from: from, cycle: cycle);
  results.add(current);
  for (int i = 1; i < count; i++) {
    current = advanceOneCycle(current, cycle);
    results.add(current);
  }
  return results;
}

/// Normalises a subscription price to a monthly amount (§2).
///
/// Weekly uses 52 weeks/year; quarterly divides by 3; yearly divides by 12.
double monthlyEquivalent(double price, BillingCycle cycle) {
  switch (cycle) {
    case BillingCycle.weekly:
      return price * 52 / 12;
    case BillingCycle.monthly:
      return price;
    case BillingCycle.quarterly:
      return price / 3;
    case BillingCycle.yearly:
      return price / 12;
  }
}

/// Normalises a subscription price to a yearly amount (§2).
double yearlyEquivalent(double price, BillingCycle cycle) {
  switch (cycle) {
    case BillingCycle.weekly:
      return price * 52;
    case BillingCycle.monthly:
      return price * 12;
    case BillingCycle.quarterly:
      return price * 4;
    case BillingCycle.yearly:
      return price;
  }
}
