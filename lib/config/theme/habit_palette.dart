import 'package:flutter/material.dart';

import '../../domain/entities/habit_color_slot.dart';

/// Resolves a [HabitColorSlot] to the concrete color to paint it with.
///
/// The dark column is not an automatic lightening of the light one: it is the
/// same eight hues re-stepped for a dark surface and validated as its own set.
///
/// Both sets were checked with the data-visualization validator against the
/// surfaces in [AppColors] and pass every gate — lightness band, chroma floor,
/// adjacent-pair separation under color-vision deficiency (worst ΔE 9.1 light /
/// 8.4 dark, target ≥ 8) and normal-vision separation (worst ΔE 19.6 / 19.3,
/// floor ≥ 15). Do not hand-edit a single hex: the palette passes as an ordered
/// set, so changing one value invalidates the guarantee for its neighbours.
///
/// Three light-mode slots (aqua, yellow, magenta) fall below 3:1 contrast on the
/// light surface. That is acceptable here only because color never carries
/// identity alone in this app — a habit is always shown next to its name. Any
/// new surface that paints a habit color *without* its label has to add a label,
/// an outline or a texture.
abstract final class HabitPalette {
  /// Steps chosen for the light chart/card surface.
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

  /// Steps chosen for the dark chart/card surface.
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

  /// The color used for days a habit was *not* completed.
  ///
  /// Deliberately a low-chroma neutral: on the year heatmap the eye should read
  /// the habit's own color as the signal and everything else as background.
  static Color inactive(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF2C2C2A)
          : const Color(0xFFE1E0D9);
}
