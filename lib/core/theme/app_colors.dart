import 'package:flutter/material.dart';

/// Centralized color tokens for the brew-assist design system.
///
/// Designed for light mode with enough token separation to support dark mode
/// later without a rewrite.
abstract final class AppColors {
  // ── Brand / Accent ──────────────────────────────────────────────────────

  /// Primary brand color — muted forest green.
  /// Used for buttons, active nav icons, selected tags, rating highlights,
  /// and gradient cards.
  static const Color primary = Color(0xFF5B7F5E);

  /// Lighter tint of primary for hover/splash states and secondary surfaces.
  static const Color primaryLight = Color(0xFF8AAE8D);

  /// Darker shade of primary for pressed states.
  static const Color primaryDark = Color(0xFF3D5B3F);

  /// Sage green — endpoint for accent gradients on feature cards.
  static const Color sage = Color(0xFFA8C5A0);

  /// Standard gradient used on feature / taste-profile cards.
  static const LinearGradient accentGradient = LinearGradient(
    colors: [primary, sage],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Neutrals ────────────────────────────────────────────────────────────

  /// Page background.
  static const Color background = Color(0xFFFFFFFF);

  /// Card / elevated surface background.
  static const Color surface = Color(0xFFF5F5F5);

  /// Slightly darker surface for nested elements or dividers.
  static const Color surfaceVariant = Color(0xFFEEEEEE);

  /// Primary text — near-black.
  static const Color textPrimary = Color(0xFF2C2C2C);

  /// Secondary / supporting text — medium gray.
  static const Color textSecondary = Color(0xFF9E9E9E);

  /// Hint / placeholder text.
  static const Color textHint = Color(0xFFBDBDBD);

  /// Disabled state foreground.
  static const Color disabled = Color(0xFFBDBDBD);

  /// Subtle border for inputs and dividers.
  static const Color border = Color(0xFFE0E0E0);

  /// White — used for text on colored backgrounds, card surfaces, etc.
  static const Color white = Color(0xFFFFFFFF);

  // ── Semantic ────────────────────────────────────────────────────────────

  /// Error / destructive actions — muted red.
  static const Color error = Color(0xFFC65D5D);

  /// Error container / background tint.
  static const Color errorLight = Color(0xFFFCE8E8);

  /// Success state.
  static const Color success = Color(0xFF5B9A5B);

  /// Warning state.
  static const Color warning = Color(0xFFD4A944);

  // ── Rating ──────────────────────────────────────────────────────────────

  /// Filled star color — matches accent green.
  static const Color ratingFilled = primary;

  /// Empty / unfilled star color.
  static const Color ratingEmpty = Color(0xFFE0E0E0);

  // ── Misc ────────────────────────────────────────────────────────────────

  /// Overlay / scrim for bottom sheets and modals.
  static const Color scrim = Color(0x66000000);

  /// Shadow color for elevation.
  static const Color shadow = Color(0x1A000000);
}
