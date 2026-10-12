import 'dart:math' as math;
import '../../data/models/reminder_enums.dart';

int daysInMonth(int year, int month) {
  if (month == 2) {
    final isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
    return isLeap ? 29 : 28;
  }
  const days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  return days[month - 1];
}

DateTime addMonthsClamped(DateTime date, int months) {
  final totalMonths = date.month - 1 + months;
  final year = date.year + totalMonths ~/ 12;
  final month = totalMonths % 12 + 1;
  final lastDay = daysInMonth(year, month);
  final day = math.min(date.day, lastDay);
  return DateTime(
    year,
    month,
    day,
    date.hour,
    date.minute,
    date.second,
    date.millisecond,
    date.microsecond,
  );
}

DateTime addSingleStep(
  DateTime current, {
  required RepeatType type,
  int interval = 1,
  RepeatUnit unit = RepeatUnit.days,
}) {
  final validInterval = interval < 1 ? 1 : interval;
  switch (type) {
    case RepeatType.none:
      return current;
    case RepeatType.daily:
      return current.add(Duration(days: validInterval));
    case RepeatType.weekly:
      return current.add(Duration(days: validInterval * 7));
    case RepeatType.monthly:
      return addMonthsClamped(current, validInterval);
    case RepeatType.yearly:
      return addMonthsClamped(current, validInterval * 12);
    case RepeatType.custom:
      switch (unit) {
        case RepeatUnit.days:
          return current.add(Duration(days: validInterval));
        case RepeatUnit.weeks:
          return current.add(Duration(days: validInterval * 7));
        case RepeatUnit.months:
          return addMonthsClamped(current, validInterval);
        case RepeatUnit.years:
          return addMonthsClamped(current, validInterval * 12);
      }
  }
}

/// Returns the next occurrence strictly after [from].
/// Pure function. Never mutates input. Never throws on valid enums.
DateTime computeNextDueDate({
  required DateTime anchor,
  required DateTime from,
  required RepeatType type,
  int interval = 1,
  RepeatUnit unit = RepeatUnit.days,
}) {
  if (type == RepeatType.none) {
    return anchor;
  }

  if (anchor.isAfter(from)) {
    return anchor;
  }

  var candidate = addSingleStep(anchor, type: type, interval: interval, unit: unit);
  while (!candidate.isAfter(from)) {
    candidate = addSingleStep(candidate, type: type, interval: interval, unit: unit);
  }

  return candidate;
}

/// Computes the next [count] upcoming occurrences strictly starting after [from] or from [anchor].
List<DateTime> computeUpcomingOccurrences({
  required DateTime anchor,
  required DateTime from,
  required RepeatType type,
  int interval = 1,
  RepeatUnit unit = RepeatUnit.days,
  int count = 3,
}) {
  if (type == RepeatType.none) {
    return [anchor];
  }

  final occurrences = <DateTime>[];
  var current = computeNextDueDate(
    anchor: anchor,
    from: from,
    type: type,
    interval: interval,
    unit: unit,
  );

  occurrences.add(current);
  for (int i = 1; i < count; i++) {
    current = addSingleStep(current, type: type, interval: interval, unit: unit);
    occurrences.add(current);
  }

  return occurrences;
}
