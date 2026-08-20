import 'package:flutter/material.dart';

import '../../config/theme/app_dimens.dart';

/// The daily check on a habit card.
///
/// A rounded square rather than a circle, because the design's shape language is
/// deliberately consistent: "checkboxes and progress indicators should use
/// rounded-lg to match the card language, rather than sharp circles".
///
/// Three states, and the third is the one that matters. A habit that cannot be
/// checked today is not an error and not a bug — it is the no-over-completion
/// rule of `ARCHITECTURE.md` §3.5 doing its job. So the disabled box stays
/// visible and keeps its shape, with the reason spelled out beside it on the
/// card. Hiding it would leave a hole in the row and make the user wonder what
/// broke.
class HabitCheckBox extends StatelessWidget {
  /// [onTap] is ignored unless [isEnabled].
  const HabitCheckBox({
    required this.accent,
    required this.isChecked,
    required this.isEnabled,
    required this.onTap,
    required this.semanticLabel,
    super.key,
  });

  /// The habit's own color, used as the fill once checked.
  final Color accent;

  /// Whether today is already done.
  final bool isChecked;

  /// Whether tapping does anything.
  final bool isEnabled;

  /// Called on tap when enabled.
  final VoidCallback onTap;

  /// What a screen reader announces, including *why* it is disabled.
  final String semanticLabel;

  /// Side of the box.
  ///
  /// 56, not the 24 the design's component notes mention: the same document
  /// asks for interactive elements no smaller than 48, and the mockups draw it
  /// at roughly this size. A 24px tap target would be missed constantly.
  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final BorderRadius radius = BorderRadius.circular(AppRadius.lg);

    // Checked fills with the habit's color. Unchecked-and-tappable keeps a
    // visible outline; unchecked-and-blocked fades that outline so the box
    // reads as inert without disappearing.
    final Color border = isEnabled ? scheme.outline : scheme.outlineVariant;

    return Semantics(
      label: semanticLabel,
      checked: isChecked,
      enabled: isEnabled,
      button: true,
      excludeSemantics: true,
      child: SizedBox(
        width: _size,
        height: _size,
        child: Material(
          color: isChecked ? accent : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side:
                isChecked
                    ? BorderSide.none
                    : BorderSide(color: border, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            // A null callback is what actually disables the ripple; a guard
            // inside the handler would still splash on a forbidden tap.
            onTap: isEnabled ? onTap : null,
            child: _CheckTick(accent: accent, isChecked: isChecked),
          ),
        ),
      ),
    );
  }
}

/// Fades the tick in and out so a tap feels answered.
class _CheckTick extends StatelessWidget {
  /// Creates the tick.
  const _CheckTick({required this.accent, required this.isChecked});

  /// The fill the tick sits on.
  final Color accent;

  /// Whether to show it.
  final bool isChecked;

  @override
  Widget build(BuildContext context) {
    // Chosen by the fill's luminance rather than fixed to white. Three light
    // slots — aqua, yellow, magenta — are bright enough that a white glyph on
    // them falls below readable contrast; on those the tick goes dark instead.
    final Color tick =
        ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
            ? Colors.white
            : Colors.black87;

    return AnimatedOpacity(
      opacity: isChecked ? 1 : 0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: Center(child: Icon(Icons.check_rounded, size: 30, color: tick)),
    );
  }
}
