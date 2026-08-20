import 'package:flutter/material.dart';

/// The *Serene Habit* color tokens, from `docs/design/DESIGN.md`.
///
/// Chrome only. The colors that identify a habit live in `HabitPalette` and are
/// kept apart on purpose: chrome must never compete with the color that says
/// *which* habit this is.
///
/// ## Where the dark column comes from
///
/// The design ships light frames only, so the dark set is derived — but not
/// invented. Material 3 token sets carry their dark counterparts inside the
/// `inverse-*` and `*-fixed-dim` slots, which is exactly what the design file
/// provides: `inverse-primary` is the dark primary, `primary-fixed-dim` its
/// dim step, `inverse-on-surface` the dark ink. Surfaces are re-stepped into
/// the same blue-tinted neutral family rather than flipped, and the habit
/// palette was re-validated against the result — see `HabitPalette`.
///
/// One deliberate departure from the token block: it lists
/// `on-surface-variant: #3c4a42`, a *green*-grey, while every surface around it
/// is blue-grey. The prose of the same document asks for "#64748B (Slate) for
/// secondary text", which is blue-grey and matches both the surfaces and the
/// mockups. The prose wins; the token looks like a generator artifact.
abstract final class AppColors {
  // --- Light: surfaces ---------------------------------------------------

  /// The plane behind the cards. Tinted, not white, so white cards lift off it.
  static const Color lightBackground = Color(0xFFF8F9FF);

  /// Card and sheet surface — pure white, and what habit colors are validated
  /// against.
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// One step up from the background, for inset or grouped areas.
  static const Color lightSurfaceContainerLow = Color(0xFFEFF4FF);

  /// Container fill for chips and the icon badge behind a habit glyph.
  static const Color lightSurfaceContainer = Color(0xFFE5EEFF);

  /// The most saturated container step — selected chips, pressed states.
  static const Color lightSurfaceContainerHigh = Color(0xFFDCE9FF);

  // --- Light: ink and lines ----------------------------------------------

  /// Primary ink for titles and values.
  static const Color lightOnSurface = Color(0xFF0B1C30);

  /// Secondary ink for supporting copy — the slate of the design's prose.
  static const Color lightOnSurfaceVariant = Color(0xFF64748B);

  /// Hairline for dividers and the rule inside a habit card.
  static const Color lightOutlineVariant = Color(0xFFDCE9FF);

  /// Visible borders — the unchecked checkbox, ghost buttons.
  static const Color lightOutline = Color(0xFF94A3B8);

  // --- Dark: surfaces ----------------------------------------------------

  /// The plane behind the cards, in the same blue-tinted family as the light
  /// neutrals rather than a neutral black.
  static const Color darkBackground = Color(0xFF101822);

  /// Card surface. Lighter than the background, mirroring how light mode puts
  /// white cards on a tinted plane — the habit palette is validated against
  /// this exact value.
  static const Color darkSurface = Color(0xFF16202C);

  /// One step up, for inset or grouped areas.
  static const Color darkSurfaceContainerLow = Color(0xFF1B2634);

  /// Container fill for chips and icon badges.
  static const Color darkSurfaceContainer = Color(0xFF213145);

  /// The most raised container step.
  static const Color darkSurfaceContainerHigh = Color(0xFF283A50);

  // --- Dark: ink and lines -----------------------------------------------

  /// Primary ink — the design's own `inverse-on-surface`.
  static const Color darkOnSurface = Color(0xFFEAF1FF);

  /// Secondary ink, the slate lifted to read on a dark surface.
  static const Color darkOnSurfaceVariant = Color(0xFF94A3B8);

  /// Hairline for dividers.
  static const Color darkOutlineVariant = Color(0xFF283A50);

  /// Visible borders.
  static const Color darkOutline = Color(0xFF64748B);

  // --- Brand: light ------------------------------------------------------

  /// Brand green. Titles, the active navigation pill, primary buttons.
  static const Color lightPrimary = Color(0xFF006C49);

  /// Ink on [lightPrimary].
  static const Color lightOnPrimary = Color(0xFFFFFFFF);

  /// The mint accent — filled containers and progress.
  static const Color lightPrimaryContainer = Color(0xFF10B981);

  /// Ink on [lightPrimaryContainer].
  static const Color lightOnPrimaryContainer = Color(0xFF00422B);

  /// Secondary brand blue.
  static const Color lightSecondary = Color(0xFF006591);

  /// Ink on [lightSecondary].
  static const Color lightOnSecondary = Color(0xFFFFFFFF);

  /// Tertiary brand amber — used by the streak flame.
  static const Color lightTertiary = Color(0xFF855300);

  /// Ink on [lightTertiary].
  static const Color lightOnTertiary = Color(0xFFFFFFFF);

  /// The amber the streak label is actually painted in — the container step,
  /// which is what the mockups show.
  static const Color lightTertiaryContainer = Color(0xFFE29100);

  /// Error red.
  static const Color lightError = Color(0xFFBA1A1A);

  /// Ink on [lightError].
  static const Color lightOnError = Color(0xFFFFFFFF);

  /// Error surface for banners.
  static const Color lightErrorContainer = Color(0xFFFFDAD6);

  /// Ink on [lightErrorContainer].
  static const Color lightOnErrorContainer = Color(0xFF93000A);

  // --- Brand: dark -------------------------------------------------------

  /// Dark primary — the design's `inverse-primary`.
  static const Color darkPrimary = Color(0xFF4EDEA3);

  /// Ink on [darkPrimary].
  static const Color darkOnPrimary = Color(0xFF003825);

  /// Dark primary container — the design's `on-primary-fixed-variant`.
  static const Color darkPrimaryContainer = Color(0xFF005236);

  /// Ink on [darkPrimaryContainer] — the design's `primary-fixed`.
  static const Color darkOnPrimaryContainer = Color(0xFF6FFBBE);

  /// Dark secondary — the design's `secondary-fixed-dim`.
  static const Color darkSecondary = Color(0xFF89CEFF);

  /// Ink on [darkSecondary].
  static const Color darkOnSecondary = Color(0xFF003350);

  /// Dark tertiary — the design's `tertiary-fixed-dim`.
  static const Color darkTertiary = Color(0xFFFFB95F);

  /// Ink on [darkTertiary].
  static const Color darkOnTertiary = Color(0xFF472A00);

  /// The amber the streak label uses on dark, same role as its light twin.
  static const Color darkTertiaryContainer = Color(0xFFFFB95F);

  /// Error red on dark.
  static const Color darkError = Color(0xFFFFB4AB);

  /// Ink on [darkError].
  static const Color darkOnError = Color(0xFF690005);

  /// Error surface for banners on dark — the light set's `on-error-container`.
  static const Color darkErrorContainer = Color(0xFF93000A);

  /// Ink on [darkErrorContainer].
  static const Color darkOnErrorContainer = Color(0xFFFFDAD6);
}
