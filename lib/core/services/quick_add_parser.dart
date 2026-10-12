import '../../data/models/reminder_enums.dart';

class QuickAddParseResult {
  final String title;
  final RepeatType repeatType;
  final int repeatInterval;
  final RepeatUnit repeatUnit;
  final DateTime dueDate;
  final DateTime? dueTime;
  final String? categoryHintId;
  final Priority priorityHint;

  const QuickAddParseResult({
    required this.title,
    this.repeatType = RepeatType.none,
    this.repeatInterval = 1,
    this.repeatUnit = RepeatUnit.days,
    required this.dueDate,
    this.dueTime,
    this.categoryHintId,
    this.priorityHint = Priority.medium,
  });
}

class QuickAddParser {
  /// Pure deterministic rule-based parser (§11.1)
  static QuickAddParseResult parse(String input, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    String raw = input.trim();

    if (raw.isEmpty) {
      return QuickAddParseResult(
        title: '',
        dueDate: today,
      );
    }

    Priority priority = Priority.medium;
    if (raw.contains('!!')) {
      priority = Priority.high;
      raw = raw.replaceAll('!!', '').trim();
    } else if (raw.contains('!')) {
      priority = Priority.high; // '!'' or '!!' mapped to high per spec rules or medium default
      raw = raw.replaceAll('!', '').trim();
    }

    RepeatType repeatType = RepeatType.none;
    int repeatInterval = 1;
    RepeatUnit repeatUnit = RepeatUnit.days;

    DateTime dueDate = today;
    DateTime? dueTime;
    String? categoryId;

    // Category Keyword Recognition
    final lowerRaw = raw.toLowerCase();
    if (lowerRaw.contains('bike') || lowerRaw.contains('car') || lowerRaw.contains('puc') || lowerRaw.contains('servicing')) {
      categoryId = 'cat_vehicle';
    } else if (lowerRaw.contains('bill') || lowerRaw.contains('rent') || lowerRaw.contains('tax') || lowerRaw.contains('insurance')) {
      categoryId = 'cat_finance';
    } else if (lowerRaw.contains('doctor') || lowerRaw.contains('dentist') || lowerRaw.contains('gym') || lowerRaw.contains('health')) {
      categoryId = 'cat_health';
    } else if (lowerRaw.contains('netflix') || lowerRaw.contains('spotify') || lowerRaw.contains('sub')) {
      categoryId = 'cat_subscriptions';
    } else if (lowerRaw.contains('water') || lowerRaw.contains('plant') || lowerRaw.contains('filter') || lowerRaw.contains('smoke detector')) {
      categoryId = 'cat_home';
    } else if (lowerRaw.contains('passport') || lowerRaw.contains('document') || lowerRaw.contains('certificate')) {
      categoryId = 'cat_documents';
    } else if (lowerRaw.contains('birthday') || lowerRaw.contains('family')) {
      categoryId = 'cat_family';
    }

    String workingTitle = raw;

    // Recurrence parsing: every N (day|week|month|year)s?
    final everyNRegex = RegExp(r'\bevery\s+(\d+)\s+(day|days|week|weeks|month|months|year|years)\b', caseSensitive: false);
    final everyNMatch = everyNRegex.firstMatch(workingTitle);
    if (everyNMatch != null) {
      repeatInterval = int.parse(everyNMatch.group(1)!);
      final unitStr = everyNMatch.group(2)!.toLowerCase();
      repeatType = RepeatType.custom;
      if (unitStr.startsWith('day')) {
        repeatUnit = RepeatUnit.days;
      } else if (unitStr.startsWith('week')) {
        repeatUnit = RepeatUnit.weeks;
      } else if (unitStr.startsWith('month')) {
        repeatUnit = RepeatUnit.months;
      } else if (unitStr.startsWith('year')) {
        repeatUnit = RepeatUnit.years;
      }
      workingTitle = workingTitle.replaceAll(everyNMatch.group(0)!, '').trim();
    } else {
      // Named recurrences: every day, every week, every month, every year
      final everyNamedRegex = RegExp(r'\bevery\s+(day|week|month|year)\b', caseSensitive: false);
      final everyNamedMatch = everyNamedRegex.firstMatch(workingTitle);
      if (everyNamedMatch != null) {
        final unitStr = everyNamedMatch.group(1)!.toLowerCase();
        repeatInterval = 1;
        if (unitStr == 'day') repeatType = RepeatType.daily;
        if (unitStr == 'week') repeatType = RepeatType.weekly;
        if (unitStr == 'month') repeatType = RepeatType.monthly;
        if (unitStr == 'year') repeatType = RepeatType.yearly;
        workingTitle = workingTitle.replaceAll(everyNamedMatch.group(0)!, '').trim();
      }
    }

    // "on the Nth" day-of-month form
    final onNthRegex = RegExp(r'\bon the\s+(\d+)(st|nd|rd|th)?\b', caseSensitive: false);
    final onNthMatch = onNthRegex.firstMatch(workingTitle);
    if (onNthMatch != null) {
      final dayNum = int.tryParse(onNthMatch.group(1)!);
      if (dayNum != null && dayNum >= 1 && dayNum <= 31) {
        final year = today.year;
        final month = today.month;
        final candidate = DateTime(year, month, dayNum);
        dueDate = candidate.isBefore(today) ? DateTime(year, month + 1, dayNum) : candidate;
      }
      workingTitle = workingTitle.replaceAll(onNthMatch.group(0)!, '').trim();
    }

    // Relative dates: today, tomorrow, next week, in N days
    final inNDaysRegex = RegExp(r'\bin\s+(\d+)\s+days?\b', caseSensitive: false);
    final inNDaysMatch = inNDaysRegex.firstMatch(workingTitle);
    if (inNDaysMatch != null) {
      final n = int.parse(inNDaysMatch.group(1)!);
      dueDate = today.add(Duration(days: n));
      workingTitle = workingTitle.replaceAll(inNDaysMatch.group(0)!, '').trim();
    } else if (RegExp(r'\btomorrow\b', caseSensitive: false).hasMatch(workingTitle)) {
      dueDate = today.add(const Duration(days: 1));
      workingTitle = workingTitle.replaceAll(RegExp(r'\btomorrow\b', caseSensitive: false), '').trim();
    } else if (RegExp(r'\btoday\b', caseSensitive: false).hasMatch(workingTitle)) {
      dueDate = today;
      workingTitle = workingTitle.replaceAll(RegExp(r'\btoday\b', caseSensitive: false), '').trim();
    } else if (RegExp(r'\bnext week\b', caseSensitive: false).hasMatch(workingTitle)) {
      dueDate = today.add(const Duration(days: 7));
      workingTitle = workingTitle.replaceAll(RegExp(r'\bnext week\b', caseSensitive: false), '').trim();
    }

    // Times: at 6pm, at 18:30, 6:00 AM
    final timeRegex = RegExp(r'\bat\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b|\b(\d{1,2}):(\d{2})\s*(am|pm)?\b', caseSensitive: false);
    final timeMatch = timeRegex.firstMatch(workingTitle);
    if (timeMatch != null) {
      int hour = 9;
      int minute = 0;
      if (timeMatch.group(1) != null) {
        hour = int.parse(timeMatch.group(1)!);
        if (timeMatch.group(2) != null) minute = int.parse(timeMatch.group(2)!);
        final ampm = timeMatch.group(3)?.toLowerCase();
        if (ampm == 'pm' && hour < 12) hour += 12;
        if (ampm == 'am' && hour == 12) hour = 0;
      } else if (timeMatch.group(4) != null) {
        hour = int.parse(timeMatch.group(4)!);
        minute = int.parse(timeMatch.group(5)!);
        final ampm = timeMatch.group(6)?.toLowerCase();
        if (ampm == 'pm' && hour < 12) hour += 12;
        if (ampm == 'am' && hour == 12) hour = 0;
      }
      dueTime = DateTime(dueDate.year, dueDate.month, dueDate.day, hour, minute);
      workingTitle = workingTitle.replaceAll(timeMatch.group(0)!, '').trim();
    }

    // Clean up title punctuation/whitespace
    String finalTitle = workingTitle
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (finalTitle.isEmpty) {
      finalTitle = raw;
    } else {
      // Capitalize first letter
      finalTitle = finalTitle[0].toUpperCase() + finalTitle.substring(1);
    }

    return QuickAddParseResult(
      title: finalTitle,
      repeatType: repeatType,
      repeatInterval: repeatInterval,
      repeatUnit: repeatUnit,
      dueDate: dueDate,
      dueTime: dueTime,
      categoryHintId: categoryId,
      priorityHint: priority,
    );
  }
}
