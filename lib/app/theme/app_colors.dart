import 'package:flutter/material.dart';

// Design authority: design.md — "Midnight Navy + Sapphire Blue".
// All finance/subscription surfaces read color from [AppFinanceColors]
// (registered as a ThemeExtension in AppTheme). No hex values may live in
// widgets; add or adjust tokens here instead.

/// Spacing scale (4dp-based) from design.md §5.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double section = 32;
}

/// Corner-radius scale from design.md §5.
abstract final class AppRadii {
  static const double control = 12; // small controls
  static const double input = 14; // inputs + standard buttons
  static const double card = 20; // cards + bottom sheets
}

/// Component heights from design.md §6.
abstract final class AppHeights {
  static const double input = 56; // price/currency + text inputs
  static const double primaryButton = 54; // primary CTA (52-56dp)
  static const double chip = 48; // billing-cycle / status chips (touch target)
  static const double brandTile = 44; // service logo tiles
}

/// Central finance/subscription color tokens (design.md §2).
///
/// Kept separate from [AppStatusColors] (which owns reminder states) so the
/// rest of the app is untouched; subscription screens read these tokens.
class AppFinanceColors extends ThemeExtension<AppFinanceColors> {
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfacePressed;
  final Color primaryPressed;
  final Color primaryTint;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color onPrimary;

  const AppFinanceColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfacePressed,
    required this.primaryPressed,
    required this.primaryTint,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.onPrimary,
  });

  /// Dark theme (primary) palette — design.md §2.
  static const dark = AppFinanceColors(
    background: Color(0xFF0B1220),
    surface: Color(0xFF151F30),
    surfaceElevated: Color(0xFF1B2940),
    surfacePressed: Color(0xFF22334D),
    primaryPressed: Color(0xFF5278E8),
    primaryTint: Color(0xFF192B50),
    textSecondary: Color(0xFFA7B4C9),
    textMuted: Color(0xFF7F8DA5),
    border: Color(0xFF2B3950),
    success: Color(0xFF42B883),
    warning: Color(0xFFF0B85A),
    error: Color(0xFFF16C76),
    info: Color(0xFF79B5FF),
    onPrimary: Color(0xFF081225),
  );

  /// Light theme mapping — design.md §3.
  static const light = AppFinanceColors(
    background: Color(0xFFF4F6FA),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    surfacePressed: Color(0xFFE9EEFA),
    primaryPressed: Color(0xFF254DCA),
    primaryTint: Color(0xFFE8EEFF),
    textSecondary: Color(0xFF56647A),
    textMuted: Color(0xFF69778D),
    border: Color(0xFFDCE3EE),
    success: Color(0xFF18794E),
    warning: Color(0xFF946200),
    error: Color(0xFFC53D4B),
    info: Color(0xFF245FC7),
    onPrimary: Color(0xFFFFFFFF),
  );

  @override
  AppFinanceColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? surfacePressed,
    Color? primaryPressed,
    Color? primaryTint,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? onPrimary,
  }) {
    return AppFinanceColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfacePressed: surfacePressed ?? this.surfacePressed,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      primaryTint: primaryTint ?? this.primaryTint,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      onPrimary: onPrimary ?? this.onPrimary,
    );
  }

  @override
  AppFinanceColors lerp(ThemeExtension<AppFinanceColors>? other, double t) {
    if (other is! AppFinanceColors) return this;
    Color lerpColor(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppFinanceColors(
      background: lerpColor(background, other.background),
      surface: lerpColor(surface, other.surface),
      surfaceElevated: lerpColor(surfaceElevated, other.surfaceElevated),
      surfacePressed: lerpColor(surfacePressed, other.surfacePressed),
      primaryPressed: lerpColor(primaryPressed, other.primaryPressed),
      primaryTint: lerpColor(primaryTint, other.primaryTint),
      textSecondary: lerpColor(textSecondary, other.textSecondary),
      textMuted: lerpColor(textMuted, other.textMuted),
      border: lerpColor(border, other.border),
      success: lerpColor(success, other.success),
      warning: lerpColor(warning, other.warning),
      error: lerpColor(error, other.error),
      info: lerpColor(info, other.info),
      onPrimary: lerpColor(onPrimary, other.onPrimary),
    );
  }
}

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

/// Central Midnight Navy + Sapphire design tokens (design.md §2–§3).
///
/// Read these only from `AppTheme` when building the [ColorScheme]; widgets
/// must keep reading `Theme.of(context).colorScheme`, never these constants
/// directly. Keeping every hex value in one place is what makes the palette
/// adjustable without scattering literals across screens.
class AppDesignTokens {
  const AppDesignTokens({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfacePressed,
    required this.primary,
    required this.primaryPressed,
    required this.primaryTint,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.onPrimary,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfacePressed;
  final Color primary;
  final Color primaryPressed;
  final Color primaryTint;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color onPrimary;

  static const dark = AppDesignTokens(
    background: Color(0xFF0B1220),
    surface: Color(0xFF151F30),
    surfaceElevated: Color(0xFF1B2940),
    surfacePressed: Color(0xFF22334D),
    primary: Color(0xFF648CFF),
    primaryPressed: Color(0xFF5278E8),
    primaryTint: Color(0xFF192B50),
    textPrimary: Color(0xFFE8EEFA),
    textSecondary: Color(0xFFA7B4C9),
    textMuted: Color(0xFF7F8DA5),
    border: Color(0xFF2B3950),
    success: Color(0xFF42B883),
    warning: Color(0xFFF0B85A),
    error: Color(0xFFF16C76),
    info: Color(0xFF79B5FF),
    onPrimary: Color(0xFF081225),
  );

  static const light = AppDesignTokens(
    background: Color(0xFFF4F6FA),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    surfacePressed: Color(0xFFE9EEFA),
    primary: Color(0xFF315FEA),
    primaryPressed: Color(0xFF254DCA),
    primaryTint: Color(0xFFE8EEFF),
    textPrimary: Color(0xFF172033),
    textSecondary: Color(0xFF56647A),
    textMuted: Color(0xFF69778D),
    border: Color(0xFFDCE3EE),
    success: Color(0xFF18794E),
    warning: Color(0xFF946200),
    error: Color(0xFFC53D4B),
    info: Color(0xFF245FC7),
    onPrimary: Color(0xFFFFFFFF),
  );
}
