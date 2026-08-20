import 'package:flutter/material.dart';

import '../../domain/entities/habit_color_slot.dart';
import 'app_colors.dart';

/// Resolves a [HabitColorSlot] to the concrete color to paint it with.
///
/// These eight are the *habit* colors — the user picks one per goal. They are
/// deliberately separate from the brand palette in [AppColors]: the design's
/// green, blue and amber dress the chrome, while these carry identity, and if
/// the two sets were one the app could not tell "this is a button" from "this is
/// the meditation habit".
///
/// The dark column is not an automatic lightening of the light one: it is the
/// same eight hues re-stepped for a dark surface and validated as its own set.
///
/// ## Validation
///
/// Re-validated on 2026-08-17 against the *Serene Habit* surfaces — the white
/// card of light mode and [AppColors.darkSurface] — after the theme moved off
/// the previous neutral tokens. Both sets still pass every gate:
///
/// | Gate | Light | Dark |
/// |---|---|---|
/// | Lightness band | pass | pass |
/// | Chroma floor | pass | pass |
/// | Adjacent pair under CVD (target ≥ 8) | 9.1 worst | 8.4 worst |
/// | Adjacent pair, normal vision (floor ≥ 15) | 19.6 worst | 19.3 worst |
/// | Contrast vs surface (≥ 3:1) | **3 below** | all pass |
///
/// Do not hand-edit a single hex: the palette passes as an *ordered set*, so
/// changing one value invalidates the guarantee for its neighbours.
///
/// The three light-mode slots below 3:1 (aqua 2.82, yellow 2.17, magenta 2.69)
/// are acceptable here only because color never carries identity alone in this
/// app — a habit is always shown next to its name. Any new surface that paints a
/// habit color *without* its label has to add a label, an outline or a texture.
abstract final class HabitPalette {
  /// Steps chosen for the white card surface of light mode.
  static const Map<HabitColorSlot, Color> _light = <HabitColorSlot, Color>{
    HabitColorSlot.blue: Color(0xFF2A78D6),
    HabitColorSlot.orange: Color(0xFFEB6834),
    HabitColorSlot.aqua: Color(0xFF1BAF7A),
    HabitColorSlot.yellow: Color(0xFFEDA100),
    HabitColorSlot.magenta: Color(0xFFE87BA4),
    HabitColorSlot.green: Color(0xFF008300),
    HabitColorSlot.violet: Color(0xFF4A3AA7),
    HabitColorSlot.red: Color(0xFFE34948),
  };

  /// Steps chosen for the dark card surface.
  static const Map<HabitColorSlot, Color> _dark = <HabitColorSlot, Color>{
    HabitColorSlot.blue: Color(0xFF3987E5),
    HabitColorSlot.orange: Color(0xFFD95926),
    HabitColorSlot.aqua: Color(0xFF199E70),
    HabitColorSlot.yellow: Color(0xFFC98500),
    HabitColorSlot.magenta: Color(0xFFD55181),
    HabitColorSlot.green: Color(0xFF008300),
    HabitColorSlot.violet: Color(0xFF9085E9),
    HabitColorSlot.red: Color(0xFFE66767),
  };

  /// Returns the color for [slot] on a surface of the given [brightness].
  static Color of(HabitColorSlot slot, Brightness brightness) {
    final Map<HabitColorSlot, Color> steps =
        brightness == Brightness.dark ? _dark : _light;
    // Every slot is present in both maps, so the lookup cannot miss.
    return steps[slot]!;
  }

  /// Returns the color for [slot] using the brightness currently in effect.
  ///
  /// Prefer this inside widgets — it keeps call sites from having to reach for
  /// the theme themselves.
  static Color resolve(BuildContext context, HabitColorSlot slot) =>
      of(slot, Theme.of(context).brightness);

  /// A faint wash of the habit's color, for the badge behind its icon.
  ///
  /// Derived rather than a fourth hard-coded map: it is the same hue at low
  /// alpha over the card, so it cannot drift out of step with [of].
  static Color wash(BuildContext context, HabitColorSlot slot) =>
      resolve(context, slot).withValues(alpha: 0.14);

  /// The color used for days a habit was *not* completed.
  ///
  /// Deliberately a low-chroma neutral from the theme's own container steps: on
  /// the year heatmap the eye should read the habit's color as the signal and
  /// everything else as background.
  static Color inactive(Brightness brightness) =>
      brightness == Brightness.dark
          ? AppColors.darkSurfaceContainer
          : AppColors.lightSurfaceContainer;
}
