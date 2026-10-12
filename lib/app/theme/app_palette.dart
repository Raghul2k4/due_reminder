import 'package:flutter/material.dart';

/// Central colour tokens for the Midnight Navy + Sapphire design system.
///
/// All subscription UI reads these tokens from the theme (`Theme.of(context)
/// .extension()`) instead of scattering hex values across
/// screens — per spec §10. Semantic colours (success/warning/error/info) are
/// reserved for statuses only; sapphire is the single brand accent.
class AppPalette extends ThemeExtension<AppPalette> {
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

  const AppPalette({
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

  /// Dark theme tokens (primary palette, spec §2).
  static const dark = AppPalette(
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

  /// Light theme mapping of the same tokens (spec §3).
  static const light = AppPalette(
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

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? surfacePressed,
    Color? primary,
    Color? primaryPressed,
    Color? primaryTint,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? onPrimary,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfacePressed: surfacePressed ?? this.surfacePressed,
      primary: primary ?? this.primary,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      primaryTint: primaryTint ?? this.primaryTint,
      textPrimary: textPrimary ?? this.textPrimary,
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
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color lerpColor(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: lerpColor(background, other.background),
      surface: lerpColor(surface, other.surface),
      surfaceElevated: lerpColor(surfaceElevated, other.surfaceElevated),
      surfacePressed: lerpColor(surfacePressed, other.surfacePressed),
      primary: lerpColor(primary, other.primary),
      primaryPressed: lerpColor(primaryPressed, other.primaryPressed),
      primaryTint: lerpColor(primaryTint, other.primaryTint),
      textPrimary: lerpColor(textPrimary, other.textPrimary),
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

/// Convenient access to the palette from a [BuildContext].
extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
