import 'package:flutter/material.dart';

/// Semantic Design Tokens for "Not To Do" — Phase 1 Color System Reset.
///
/// Dark Mode: "Cosmic Obsidian & Wasabi Glow" — OLED-optimized, zero eye-strain,
/// high-voltage accent for Gen Z focus-state engagement.
///
/// Light Mode: "Matcha Oat Latte" — warm, grounding, anti-clinical cream tones
/// for daylight outdoor readability.
class AppColors {
  AppColors._();

  // ================================================================
  // LIGHT MODE — "Matcha Oat Latte"
  // ================================================================

  // Primary — Deep Sage (grounding, calm, focus-affirming)
  static const Color lightPrimary = Color(0xFF2D6A4F);
  static const Color lightPrimaryContainer = Color(0xFF95D5B2);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightOnPrimaryContainer = Color(0xFF0A2818);
  static const Color lightPrimaryFixed = Color(0xFFB7E4C7);
  static const Color lightPrimaryFixedDim = Color(0xFF74C69D);
  static const Color lightOnPrimaryFixed = Color(0xFF0A2818);

  // Secondary — Alert Coral (anti-habit barriers, destructive actions)
  static const Color lightSecondary = Color(0xFFE63946);
  static const Color lightSecondaryContainer = Color(0xFFFFD7DA);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightOnSecondaryContainer = Color(0xFF400010);
  static const Color lightSecondaryFixed = Color(0xFFFFE5E8);
  static const Color lightSecondaryFixedDim = Color(0xFFFFACB5);
  static const Color lightOnSecondaryFixed = Color(0xFF400010);
  static const Color lightAntiHabitRose = Color(0xFFE63946);
  static const Color lightAntiHabitBg = Color(0xFFFFF1F2);

  // Tertiary — Muted Lavender (academic tags, course badges, routine items)
  static const Color lightTertiary = Color(0xFF7C6FBF);
  static const Color lightTertiaryContainer = Color(0xFFE8E0FF);
  static const Color lightOnTertiary = Color(0xFFFFFFFF);
  static const Color lightOnTertiaryContainer = Color(0xFF1A1040);
  static const Color lightTertiaryFixed = Color(0xFFEDE6FF);
  static const Color lightTertiaryFixedDim = Color(0xFFB8AADF);
  static const Color lightOnTertiaryFixed = Color(0xFF1A1040);
  static const Color lightAcademicSky = Color(0xFF7C6FBF);
  static const Color lightAcademicBg = Color(0xFFF3EEFF);

  // Surfaces — Warm Oat Cream (NOT sterile white)
  static const Color lightBackground = Color(0xFFFBF9F5);
  static const Color lightSurface = Color(0xFFFBF9F5);
  static const Color lightSurfaceCanvas = Color(0xFFFBF9F5);
  static const Color lightSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainerLow = Color(0xFFF8F6F1);
  static const Color lightSurfaceContainer = Color(0xFFF2F0EB);
  static const Color lightSurfaceContainerHigh = Color(0xFFEDEAE4);
  static const Color lightSurfaceContainerHighest = Color(0xFFE5E2DC);

  // Typography & Outlines
  static const Color lightOnSurface = Color(0xFF1A1D23);
  static const Color lightOnSurfaceVariant = Color(0xFF5A6270);
  static const Color lightTextSecondary = Color(0xFF5A6270);
  static const Color lightTextMuted = Color(0xFF94A3B8);
  static const Color lightOutline = Color(0xFF8C9196);
  static const Color lightOutlineVariant = Color(0xFFD0D3D8);
  static const Color lightCardBorder = Color(0xFFE2E5DB);

  // Error
  static const Color lightError = Color(0xFFC62828);
  static const Color lightOnError = Color(0xFFFFFFFF);
  static const Color lightErrorContainer = Color(0xFFFFCDD2);
  static const Color lightOnErrorContainer = Color(0xFF400010);

  // Accent Tokens — Warning, Success, Accent
  static const Color lightWarning = Color(0xFFE09F3E);
  static const Color lightWarningBg = Color(0xFFFFF8E8);
  static const Color lightSuccess = Color(0xFF40916C);
  static const Color lightSuccessBg = Color(0xFFE8F5EE);
  static const Color lightAccent = Color(0xFF6366F1);
  static const Color lightAccentBg = Color(0xFFEEF0FF);

  // ================================================================
  // DARK MODE — "Cosmic Obsidian & Wasabi Glow"
  // ================================================================

  // Primary — Wasabi Glow (high-voltage CTA, focus ring, active timer)
  static const Color darkPrimary = Color(0xFFA6FF00);
  static const Color darkPrimaryContainer = Color(0xFF3D5C00);
  static const Color darkOnPrimary = Color(0xFF0B0C10);
  static const Color darkOnPrimaryContainer = Color(0xFFD4FF80);
  static const Color darkPrimaryFixed = Color(0xFFC6FF4D);
  static const Color darkPrimaryFixedDim = Color(0xFF8CD400);
  static const Color darkOnPrimaryFixed = Color(0xFF1A2E00);

  // Secondary — Hyper Magenta (anti-habit shields, breach alerts, urgent flags)
  static const Color darkSecondary = Color(0xFFFF2A85);
  static const Color darkSecondaryContainer = Color(0xFF8C0042);
  static const Color darkOnSecondary = Color(0xFFFFFFFF);
  static const Color darkOnSecondaryContainer = Color(0xFFFFD6E8);
  static const Color darkSecondaryFixed = Color(0xFF4D0028);
  static const Color darkSecondaryFixedDim = Color(0xFF800040);
  static const Color darkOnSecondaryFixed = Color(0xFFFFD6E8);
  static const Color darkAntiHabitRose = Color(0xFFFF2A85);
  static const Color darkAntiHabitBg = Color(0xFF2A0E1F);

  // Tertiary — Digital Lavender (academic tags, course badges, knowledge)
  static const Color darkTertiary = Color(0xFFC8B6FF);
  static const Color darkTertiaryContainer = Color(0xFF4A3D8F);
  static const Color darkOnTertiary = Color(0xFF0B0C10);
  static const Color darkOnTertiaryContainer = Color(0xFFE8E0FF);
  static const Color darkTertiaryFixed = Color(0xFFDDD4FF);
  static const Color darkTertiaryFixedDim = Color(0xFFB0A0E8);
  static const Color darkOnTertiaryFixed = Color(0xFF1A1040);
  static const Color darkAcademicSky = Color(0xFFC8B6FF);
  static const Color darkAcademicBg = Color(0xFF1A1430);

  // Surfaces — Obsidian Void (OLED-optimized, NOT pure #000000)
  static const Color darkBackground = Color(0xFF0B0C10);
  static const Color darkSurface = Color(0xFF0E1015);
  static const Color darkSurfaceCanvas = Color(0xFF0B0C10);
  static const Color darkSurfaceContainerLowest = Color(0xFF080A0E);
  static const Color darkSurfaceContainerLow = Color(0xFF111420);
  static const Color darkSurfaceContainer = Color(0xFF161822);
  static const Color darkSurfaceContainerHigh = Color(0xFF1C2030);
  static const Color darkSurfaceContainerHighest = Color(0xFF232838);

  // Typography & Outlines (87% rule — soft off-white, no glare)
  static const Color darkOnSurface = Color(0xFFE6EAF2);
  static const Color darkOnSurfaceVariant = Color(0xFF8892A8);
  static const Color darkTextSecondary = Color(0xFF8892A8);
  static const Color darkTextMuted = Color(0xFF5C6378);
  static const Color darkOutline = Color(0xFF22263A);
  static const Color darkOutlineVariant = Color(0xFF1A1D27);
  static const Color darkCardBorder = Color(0xFF22263A);

  // Error
  static const Color darkError = Color(0xFFFF6B8A);
  static const Color darkOnError = Color(0xFF400020);
  static const Color darkErrorContainer = Color(0xFF800040);
  static const Color darkOnErrorContainer = Color(0xFFFFD6E8);

  // Accent Tokens — Warning, Success, Accent
  static const Color darkWarning = Color(0xFFFFB800);
  static const Color darkWarningBg = Color(0xFF2A2000);
  static const Color darkSuccess = Color(0xFF38EFC1);
  static const Color darkSuccessBg = Color(0xFF0D2E24);
  static const Color darkAccent = Color(0xFF818CF8);
  static const Color darkAccentBg = Color(0xFF1A1840);

  // Legacy aliases (backward compatibility for screens with direct references)
  static const Color darkAmber = Color(0xFFFFB800);
  static const Color darkViolet = Color(0xFF818CF8);

  /// Typed access helper — resolves AppCustomColors from current theme.
  static AppCustomColors of(BuildContext context) {
    return Theme.of(context).extension<AppCustomColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppCustomColors.dark
            : AppCustomColors.light);
  }
}

/// ThemeExtension providing typed semantic tokens for all UI components.
/// 23 fields: 17 original + 6 new (warning, warningBg, success, successBg, accent, accentBg).
@immutable
class AppCustomColors extends ThemeExtension<AppCustomColors> {
  // ---- Original 17 fields (preserved for backward compat) ----
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

  // ---- New 6 fields (Phase 1 additions) ----
  final Color warning;
  final Color warningBg;
  final Color success;
  final Color successBg;
  final Color accent;
  final Color accentBg;

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
    required this.warning,
    required this.warningBg,
    required this.success,
    required this.successBg,
    required this.accent,
    required this.accentBg,
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
    warning: AppColors.lightWarning,
    warningBg: AppColors.lightWarningBg,
    success: AppColors.lightSuccess,
    successBg: AppColors.lightSuccessBg,
    accent: AppColors.lightAccent,
    accentBg: AppColors.lightAccentBg,
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
    warning: AppColors.darkWarning,
    warningBg: AppColors.darkWarningBg,
    success: AppColors.darkSuccess,
    successBg: AppColors.darkSuccessBg,
    accent: AppColors.darkAccent,
    accentBg: AppColors.darkAccentBg,
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
    Color? warning,
    Color? warningBg,
    Color? success,
    Color? successBg,
    Color? accent,
    Color? accentBg,
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
      warning: warning ?? this.warning,
      warningBg: warningBg ?? this.warningBg,
      success: success ?? this.success,
      successBg: successBg ?? this.successBg,
      accent: accent ?? this.accent,
      accentBg: accentBg ?? this.accentBg,
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
      warning: Color.lerp(warning, other.warning, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      success: Color.lerp(success, other.success, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentBg: Color.lerp(accentBg, other.accentBg, t)!,
    );
  }
}
