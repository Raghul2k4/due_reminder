import 'package:flutter/material.dart';

class AppStatusColors extends ThemeExtension<AppStatusColors> {
  final Color overdue;
  final Color today;
  final Color upcoming;
  final Color completed;
  final Color snoozed;

  const AppStatusColors({
    required this.overdue,
    required this.today,
    required this.upcoming,
    required this.completed,
    required this.snoozed,
  });

  static const light = AppStatusColors(
    overdue: Color(0xFFD32F2F),
    today: Color(0xFFED6C02),
    upcoming: Color(0xFF0288D1),
    completed: Color(0xFF757575),
    snoozed: Color(0xFF9C27B0),
  );

  static const dark = AppStatusColors(
    overdue: Color(0xFFEF5350),
    today: Color(0xFFFF9800),
    upcoming: Color(0xFF29B6F6),
    completed: Color(0xFFB0BEC5),
    snoozed: Color(0xFFAB47BC),
  );

  @override
  AppStatusColors copyWith({
    Color? overdue,
    Color? today,
    Color? upcoming,
    Color? completed,
    Color? snoozed,
  }) {
    return AppStatusColors(
      overdue: overdue ?? this.overdue,
      today: today ?? this.today,
      upcoming: upcoming ?? this.upcoming,
      completed: completed ?? this.completed,
      snoozed: snoozed ?? this.snoozed,
    );
  }

  @override
  AppStatusColors lerp(ThemeExtension<AppStatusColors>? other, double t) {
    if (other is! AppStatusColors) return this;
    return AppStatusColors(
      overdue: Color.lerp(overdue, other.overdue, t)!,
      today: Color.lerp(today, other.today, t)!,
      upcoming: Color.lerp(upcoming, other.upcoming, t)!,
      completed: Color.lerp(completed, other.completed, t)!,
      snoozed: Color.lerp(snoozed, other.snoozed, t)!,
    );
  }
}
