import 'package:flutter/material.dart';

/// Semantic Design Tokens for "Not To Do" Routine Tracker.
/// Extracted directly from Stitch Design System: Clarity Anti-Habit & Academic Architecture.
class AppColors {
  AppColors._();

  // ==========================================
  // LIGHT MODE TOKENS
  // ==========================================
  static const Color lightPrimary = Color(0xFF006948);
  static const Color lightPrimaryContainer = Color(0xFF00855D);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightOnPrimaryContainer = Color(0xFFF5FFF7);
  static const Color lightPrimaryFixed = Color(0xFF85F8C4);
  static const Color lightPrimaryFixedDim = Color(0xFF68DBA9);
  static const Color lightOnPrimaryFixed = Color(0xFF002114);

  // Anti-Habit / Prohibited ("Not To Do") Crimson Tokens
  static const Color lightSecondary = Color(0xFFBA0035);
  static const Color lightSecondaryContainer = Color(0xFFE21E49);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightOnSecondaryContainer = Color(0xFFFEF2F2);
  static const Color lightSecondaryFixed = Color(0xFFFFDADA);
  static const Color lightSecondaryFixedDim = Color(0xFFFFB3B6);
  static const Color lightOnSecondaryFixed = Color(0xFF40000C);
  static const Color lightAntiHabitRose = Color(0xFFF43F5E);
  static const Color lightAntiHabitBg = Color(0xFFFFF1F2);

  // Academic Timetable & Scheduling Sky Blue Tokens
  static const Color lightTertiary = Color(0xFF006194);
  static const Color lightTertiaryContainer = Color(0xFF007BB9);
  static const Color lightOnTertiary = Color(0xFFFFFFFF);
  static const Color lightOnTertiaryContainer = Color(0xFFFDFCFF);
  static const Color lightTertiaryFixed = Color(0xFFCCE5FF);
  static const Color lightTertiaryFixedDim = Color(0xFF93CCFF);
  static const Color lightOnTertiaryFixed = Color(0xFF001D31);
  static const Color lightAcademicSky = Color(0xFF0284C7);
  static const Color lightAcademicBg = Color(0xFFF0F9FF);

  // Surfaces & Backgrounds
  static const Color lightBackground = Color(0xFFFAF8FF);
  static const Color lightSurface = Color(0xFFFAF8FF);
  static const Color lightSurfaceCanvas = Color(0xFFF4F8F5);
  static const Color lightSurfaceContainerLowest = Color(0xFFFFFFFF); // Card white
  static const Color lightSurfaceContainerLow = Color(0xFFF2F3FF);
  static const Color lightSurfaceContainer = Color(0xFFEAEDFF);
  static const Color lightSurfaceContainerHigh = Color(0xFFE2E7FF);
  static const Color lightSurfaceContainerHighest = Color(0xFFDAE2FD);

  // Typography & Outlines
  static const Color lightOnSurface = Color(0xFF131B2E);
  static const Color lightOnSurfaceVariant = Color(0xFF3D4A42);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextMuted = Color(0xFF94A3B8);
  static const Color lightOutline = Color(0xFF6D7A72);
  static const Color lightOutlineVariant = Color(0xFFBCCAC0);
  static const Color lightCardBorder = Color(0xFFE2ECE6);

  // Error & Alerts
  static const Color lightError = Color(0xFFBA1A1A);
  static const Color lightOnError = Color(0xFFFFFFFF);
  static const Color lightErrorContainer = Color(0xFFFFDAD6);
  static const Color lightOnErrorContainer = Color(0xFF93000A);

  // ==========================================
  // DARK MODE TOKENS
  // ==========================================
  static const Color darkPrimary = Color(0xFF4EDEA3);
  static const Color darkPrimaryContainer = Color(0xFF10B981);
  static const Color darkOnPrimary = Color(0xFF003824);
  static const Color darkOnPrimaryContainer = Color(0xFF00422B);
  static const Color darkPrimaryFixed = Color(0xFF6FFBBE);
  static const Color darkPrimaryFixedDim = Color(0xFF4EDEA3);
  static const Color darkOnPrimaryFixed = Color(0xFF002113);

  // Anti-Habit / Crimson Rose Dark Tokens
  static const Color darkSecondary = Color(0xFFFB7185);
  static const Color darkSecondaryContainer = Color(0xFFF43F5E);
  static const Color darkOnSecondary = Color(0xFF40000C);
  static const Color darkOnSecondaryContainer = Color(0xFFFFDAD6);
  static const Color darkSecondaryFixed = Color(0xFF690005);
  static const Color darkSecondaryFixedDim = Color(0xFF93000A);
  static const Color darkOnSecondaryFixed = Color(0xFFFFDAD6);
  static const Color darkAntiHabitRose = Color(0xFFF43F5E);
  static const Color darkAntiHabitBg = Color(0xFF2A1017);

  // Academic Timetable Sky Blue Dark Tokens
  static const Color darkTertiary = Color(0xFF38BDF8);
  static const Color darkTertiaryContainer = Color(0xFF00885D);
  static const Color darkOnTertiary = Color(0xFF00354A);
  static const Color darkOnTertiaryContainer = Color(0xFF000703);
  static const Color darkTertiaryFixed = Color(0xFFC4E7FF);
  static const Color darkTertiaryFixedDim = Color(0xFF7BD0FF);
  static const Color darkOnTertiaryFixed = Color(0xFF001E2C);
  static const Color darkAcademicSky = Color(0xFF38BDF8);
  static const Color darkAcademicBg = Color(0xFF0C2438);

  // Surfaces & Backgrounds Dark
  static const Color darkBackground = Color(0xFF081C15);
  static const Color darkSurface = Color(0xFF081C15);
  static const Color darkSurfaceCanvas = Color(0xFF041710);
  static const Color darkSurfaceContainerLowest = Color(0xFF041710);
  static const Color darkSurfaceContainerLow = Color(0xFF0B1F18);
  static const Color darkSurfaceContainer = Color(0xFF0E231B); // Card dark
  static const Color darkSurfaceContainerHigh = Color(0xFF132E24);
  static const Color darkSurfaceContainerHighest = Color(0xFF1A2E26);

  // Typography & Outlines Dark
  static const Color darkOnSurface = Color(0xFFECFDF5);
  static const Color darkOnSurfaceVariant = Color(0xFFA7F3D0);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF6EE7B7);
  static const Color darkOutline = Color(0xFF1E3D32);
  static const Color darkOutlineVariant = Color(0xFF143328);
  static const Color darkCardBorder = Color(0xFF1E3D32);

  // Error Dark
  static const Color darkError = Color(0xFFFFB4AB);
  static const Color darkOnError = Color(0xFF690005);
  static const Color darkErrorContainer = Color(0xFF93000A);
  static const Color darkOnErrorContainer = Color(0xFFFFDAD6);

  /// Helper to get custom app tokens depending on theme brightness
  static AppCustomColors of(BuildContext context) {
    return Theme.of(context).extension<AppCustomColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppCustomColors.dark
            : AppCustomColors.light);
  }
}

/// ThemeExtension to give typed access to Stitch semantic tokens.
@immutable
class AppCustomColors extends ThemeExtension<AppCustomColors> {
  final Color primaryAccent;
  final Color primaryFixed;
  final Color onPrimaryFixed;
  final Color antiHabit;
  final Color antiHabitBg;
  final Color antiHabitText;
  final Color academic;
  final Color academicBg;
  final Color cardBackground;
  final Color cardBorder;
  final Color canvasBackground;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color chipInactiveBg;
  final Color chipInactiveBorder;
  final Color chipInactiveText;

  const AppCustomColors({
    required this.primaryAccent,
    required this.primaryFixed,
    required this.onPrimaryFixed,
    required this.antiHabit,
    required this.antiHabitBg,
    required this.antiHabitText,
    required this.academic,
    required this.academicBg,
    required this.cardBackground,
    required this.cardBorder,
    required this.canvasBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.chipInactiveBg,
    required this.chipInactiveBorder,
    required this.chipInactiveText,
  });

  static const AppCustomColors light = AppCustomColors(
    primaryAccent: AppColors.lightPrimary,
    primaryFixed: AppColors.lightPrimaryFixed,
    onPrimaryFixed: AppColors.lightOnPrimaryFixed,
    antiHabit: AppColors.lightAntiHabitRose,
    antiHabitBg: AppColors.lightAntiHabitBg,
    antiHabitText: AppColors.lightSecondary,
    academic: AppColors.lightAcademicSky,
    academicBg: AppColors.lightAcademicBg,
    cardBackground: AppColors.lightSurfaceContainerLowest,
    cardBorder: AppColors.lightCardBorder,
    canvasBackground: AppColors.lightSurfaceCanvas,
    textPrimary: AppColors.lightOnSurface,
    textSecondary: AppColors.lightOnSurfaceVariant,
    textMuted: AppColors.lightTextMuted,
    chipInactiveBg: AppColors.lightSurfaceContainer,
    chipInactiveBorder: AppColors.lightCardBorder,
    chipInactiveText: AppColors.lightOnSurfaceVariant,
  );

  static const AppCustomColors dark = AppCustomColors(
    primaryAccent: AppColors.darkPrimary,
    primaryFixed: AppColors.darkPrimaryFixed,
    onPrimaryFixed: AppColors.darkOnPrimaryFixed,
    antiHabit: AppColors.darkAntiHabitRose,
    antiHabitBg: AppColors.darkAntiHabitBg,
    antiHabitText: AppColors.darkSecondary,
    academic: AppColors.darkAcademicSky,
    academicBg: AppColors.darkAcademicBg,
    cardBackground: AppColors.darkSurfaceContainer,
    cardBorder: AppColors.darkCardBorder,
    canvasBackground: AppColors.darkBackground,
    textPrimary: AppColors.darkOnSurface,
    textSecondary: AppColors.darkOnSurfaceVariant,
    textMuted: AppColors.darkTextMuted,
    chipInactiveBg: AppColors.darkSurfaceContainerLow,
    chipInactiveBorder: AppColors.darkOutline,
    chipInactiveText: AppColors.darkOnSurfaceVariant,
  );

  @override
  ThemeExtension<AppCustomColors> copyWith({
    Color? primaryAccent,
    Color? primaryFixed,
    Color? onPrimaryFixed,
    Color? antiHabit,
    Color? antiHabitBg,
    Color? antiHabitText,
    Color? academic,
    Color? academicBg,
    Color? cardBackground,
    Color? cardBorder,
    Color? canvasBackground,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? chipInactiveBg,
    Color? chipInactiveBorder,
    Color? chipInactiveText,
  }) {
    return AppCustomColors(
      primaryAccent: primaryAccent ?? this.primaryAccent,
      primaryFixed: primaryFixed ?? this.primaryFixed,
      onPrimaryFixed: onPrimaryFixed ?? this.onPrimaryFixed,
      antiHabit: antiHabit ?? this.antiHabit,
      antiHabitBg: antiHabitBg ?? this.antiHabitBg,
      antiHabitText: antiHabitText ?? this.antiHabitText,
      academic: academic ?? this.academic,
      academicBg: academicBg ?? this.academicBg,
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      canvasBackground: canvasBackground ?? this.canvasBackground,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      chipInactiveBg: chipInactiveBg ?? this.chipInactiveBg,
      chipInactiveBorder: chipInactiveBorder ?? this.chipInactiveBorder,
      chipInactiveText: chipInactiveText ?? this.chipInactiveText,
    );
  }

  @override
  ThemeExtension<AppCustomColors> lerp(
    covariant ThemeExtension<AppCustomColors>? other,
    double t,
  ) {
    if (other is! AppCustomColors) return this;
    return AppCustomColors(
      primaryAccent: Color.lerp(primaryAccent, other.primaryAccent, t)!,
      primaryFixed: Color.lerp(primaryFixed, other.primaryFixed, t)!,
      onPrimaryFixed: Color.lerp(onPrimaryFixed, other.onPrimaryFixed, t)!,
      antiHabit: Color.lerp(antiHabit, other.antiHabit, t)!,
      antiHabitBg: Color.lerp(antiHabitBg, other.antiHabitBg, t)!,
      antiHabitText: Color.lerp(antiHabitText, other.antiHabitText, t)!,
      academic: Color.lerp(academic, other.academic, t)!,
      academicBg: Color.lerp(academicBg, other.academicBg, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      canvasBackground: Color.lerp(canvasBackground, other.canvasBackground, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      chipInactiveBg: Color.lerp(chipInactiveBg, other.chipInactiveBg, t)!,
      chipInactiveBorder: Color.lerp(chipInactiveBorder, other.chipInactiveBorder, t)!,
      chipInactiveText: Color.lerp(chipInactiveText, other.chipInactiveText, t)!,
    );
  }
}
