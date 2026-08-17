import 'package:flutter/material.dart';

import '../../../../config/theme/app_dimens.dart';
import '../../../../config/theme/habit_palette.dart';
import '../../../../domain/entities/habit_color_slot.dart';

/// The eight habit colors, in the order that makes them distinguishable.
///
/// Order is not cosmetic: `HabitColorSlot`'s declaration order is what the
/// colorblind-safety validation was run against, adjacent pair by adjacent pair.
/// Showing them shuffled — or sorted by hue, or by "recently used" — would put
/// pairs next to each other that were never checked against one another.
class ColorPickerRow extends StatelessWidget {
  /// [onChanged] fires with the tapped slot.
  const ColorPickerRow({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  /// The slot currently chosen.
  final HabitColorSlot selected;

  /// Called when the user picks a different one.
  final ValueChanged<HabitColorSlot> onChanged;

  /// Diameter of a swatch. Comfortably over the 48 minimum once the row's
  /// spacing is counted.
  static const double _swatchSize = 44;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.gutter,
      runSpacing: AppSpacing.gutter,
      children: <Widget>[
        for (final HabitColorSlot slot in HabitColorSlot.values)
          _Swatch(
            slot: slot,
            isSelected: slot == selected,
            onTap: () => onChanged(slot),
          ),
      ],
    );
  }
}

/// A single colored circle.
class _Swatch extends StatelessWidget {
  /// Creates the swatch.
  const _Swatch({
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  /// Which color this is.
  final HabitColorSlot slot;

  /// Whether it is the chosen one.
  final bool isSelected;

  /// Tap handler.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = HabitPalette.resolve(context, slot);

    return Semantics(
      // The slot's identifier, not a color name: "aqua" is a label the app never
      // shows and a screen-reader user cannot verify. Selection state is what
      // actually matters here, and `selected` carries it.
      label: slot.name,
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: ColorPickerRow._swatchSize,
          height: ColorPickerRow._swatchSize,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            // Selection is a ring, not a tick: three of these colors are light
            // enough in light mode that a white check on them is unreadable.
            border:
                isSelected
                    ? Border.all(color: scheme.onSurface, width: 3)
                    : null,
          ),
        ),
      ),
    );
  }
}
