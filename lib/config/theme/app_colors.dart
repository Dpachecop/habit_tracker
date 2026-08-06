import 'package:flutter/material.dart';

/// Surface and ink tokens for the app chrome.
///
/// These are the neutrals only. Habit colors live in `HabitPalette` and are
/// kept apart on purpose: chrome must never compete with the color that
/// identifies a habit.
abstract final class AppColors {
  // --- Light -------------------------------------------------------------

  /// Card and chart surface — what habit colors are validated against.
  static const Color lightSurface = Color(0xFFFCFCFB);

  /// The plane behind the cards, a touch darker so surfaces lift off it.
  static const Color lightBackground = Color(0xFFF9F9F7);

  /// Primary ink for titles and values.
  static const Color lightTextPrimary = Color(0xFF0B0B0B);

  /// Secondary ink for supporting copy.
  static const Color lightTextSecondary = Color(0xFF52514E);

  /// Hairline used for gridlines and dividers.
  static const Color lightGridline = Color(0xFFE1E0D9);

  /// Axis and baseline strokes.
  static const Color lightAxis = Color(0xFFC3C2B7);

  // --- Dark --------------------------------------------------------------

  /// Card and chart surface for dark mode.
  static const Color darkSurface = Color(0xFF1A1A19);

  /// The plane behind the cards in dark mode.
  static const Color darkBackground = Color(0xFF0D0D0D);

  /// Primary ink for titles and values.
  static const Color darkTextPrimary = Color(0xFFFFFFFF);

  /// Secondary ink for supporting copy.
  static const Color darkTextSecondary = Color(0xFFC3C2B7);

  /// Hairline used for gridlines and dividers.
  static const Color darkGridline = Color(0xFF2C2C2A);

  /// Axis and baseline strokes.
  static const Color darkAxis = Color(0xFF383835);

  // --- Shared ------------------------------------------------------------

  /// Muted ink for axis ticks and de-emphasised labels.
  ///
  /// Intentionally the same in both themes: it clears contrast on either
  /// surface, and a single token keeps chart axes looking identical.
  static const Color muted = Color(0xFF898781);
}
