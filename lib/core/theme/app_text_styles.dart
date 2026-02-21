import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Text style tokens for the brew-assist design system.
///
/// All styles use **Plus Jakarta Sans** via the `google_fonts` package.
/// The class provides both a complete [TextTheme] for Material integration
/// and individual named constants for direct use in widgets.
abstract final class AppTextStyles {
  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Base Plus Jakarta Sans style that all others derive from.
  static TextStyle _base({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    double height = 1.5,
    double letterSpacing = 0,
    Color color = AppColors.textPrimary,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  // ── Display ─────────────────────────────────────────────────────────────

  static final TextStyle displayLarge = _base(
    fontSize: 57,
    fontWeight: FontWeight.w700,
    height: 1.12,
    letterSpacing: -0.25,
  );

  static final TextStyle displayMedium = _base(
    fontSize: 45,
    fontWeight: FontWeight.w700,
    height: 1.16,
  );

  static final TextStyle displaySmall = _base(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    height: 1.22,
  );

  // ── Headline ────────────────────────────────────────────────────────────

  static final TextStyle headlineLarge = _base(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  static final TextStyle headlineMedium = _base(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.29,
  );

  static final TextStyle headlineSmall = _base(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );

  // ── Title ───────────────────────────────────────────────────────────────

  static final TextStyle titleLarge = _base(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.27,
  );

  static final TextStyle titleMedium = _base(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0.15,
  );

  static final TextStyle titleSmall = _base(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43,
    letterSpacing: 0.1,
  );

  // ── Body ────────────────────────────────────────────────────────────────

  static final TextStyle bodyLarge = _base(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.5,
  );

  static final TextStyle bodyMedium = _base(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    letterSpacing: 0.25,
  );

  static final TextStyle bodySmall = _base(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
    letterSpacing: 0.4,
  );

  // ── Label ───────────────────────────────────────────────────────────────

  static final TextStyle labelLarge = _base(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43,
    letterSpacing: 0.1,
  );

  static final TextStyle labelMedium = _base(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.33,
    letterSpacing: 0.5,
  );

  static final TextStyle labelSmall = _base(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.45,
    letterSpacing: 0.5,
  );

  // ── App-specific convenience styles ─────────────────────────────────────

  /// Large numeric rating display (e.g. "4.2").
  static final TextStyle ratingLarge = _base(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.0,
  );

  /// Small numeric rating display (e.g. "4.2" on cards).
  static final TextStyle ratingSmall = _base(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.0,
  );

  /// Stat number on profile (check-in count, followers, etc.).
  static final TextStyle statNumber = _base(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  /// Stat label below the number.
  static final TextStyle statLabel = _base(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
    color: AppColors.textSecondary,
  );

  /// Chip / tag text.
  static final TextStyle chip = _base(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.23,
  );

  /// Button text.
  static final TextStyle button = _base(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43,
    letterSpacing: 0.1,
  );

  // ── Material TextTheme ──────────────────────────────────────────────────

  /// Complete [TextTheme] wired to Plus Jakarta Sans for passing into
  /// [ThemeData.textTheme].
  static TextTheme get textTheme => TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        displaySmall: AppTextStyles.displaySmall,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      );
}
