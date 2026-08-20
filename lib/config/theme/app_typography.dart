import 'package:flutter/material.dart';

import 'app_dimens.dart';

/// The Inter type scale from `docs/design/DESIGN.md`, mapped onto Material's
/// slots.
///
/// The design names its styles by role (`display`, `headline-lg`, `body-md`,
/// `label-caps`); Flutter's `TextTheme` names them by size. Mapping them once
/// here means widgets keep using `Theme.of(context).textTheme` — the idiomatic
/// path, which also gets them scaling and inheritance for free — instead of
/// reaching for a parallel set of custom styles.
///
/// Line heights are expressed as Flutter's `height` multiplier, which is
/// line-height ÷ font-size. Letter spacing is in logical pixels, so the
/// design's em values are multiplied by the font size.
abstract final class AppTypography {
  /// The bundled family. Three static weights (400/600/700) rather than the
  /// variable file, because a variable font in Flutter needs `fontVariations`
  /// at every call site and `fontWeight` would silently do nothing.
  static const String fontFamily = 'Inter';

  /// Builds the text theme. [ink] is the primary text color; secondary copy
  /// gets its color at the call site, where the distinction is meaningful.
  static TextTheme build(Color ink) {
    return TextTheme(
      // display — 32/40, bold, -0.02em. The screen title.
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 40 / 32,
        letterSpacing: 32 * -0.02,
        color: ink,
      ),
      // headline-lg — 24/32, semibold, -0.01em. Section headings.
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
        letterSpacing: 24 * -0.01,
        color: ink,
      ),
      // headline-lg-mobile — 22/28, semibold. The greeting.
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 28 / 22,
        color: ink,
      ),
      // headline-md — 20/28, semibold. A habit's name.
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
        color: ink,
      ),
      // body-lg — 16/24, regular.
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: ink,
      ),
      // body-md — 14/20, regular. Supporting copy.
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: ink,
      ),
      // label-caps — 12/16, semibold, +0.05em. Section labels and category
      // tags. The design asks for it to be visually distinct from actionable
      // body text, which the tracking is what achieves.
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 16 / 12,
        letterSpacing: 12 * 0.05,
        color: ink,
      ),
      // Frequency chips and the navigation bar sit between body and label.
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        color: ink,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 16 / 12,
        color: ink,
      ),
    );
  }

  /// The section-label style, uppercased at the call site.
  ///
  /// `label-caps` is the one style whose *casing* is part of it, and Flutter has
  /// no text-transform. Exposed as a named accessor so no widget has to
  /// remember which slot it landed in.
  static TextStyle labelCaps(BuildContext context) =>
      Theme.of(context).textTheme.labelSmall!;

  /// Vertical rhythm helper: the design's 4px base, in case a widget needs to
  /// compute a height rather than pad.
  static const double baseUnit = AppSpacing.base;
}
