/// Spacing and corner radii from `docs/design/DESIGN.md`.
///
/// Named constants rather than magic numbers at call sites, so the 4px rhythm
/// the design asks for is enforced by the type system instead of by memory. A
/// widget that needs 13px of padding is a widget that has drifted off the grid.
abstract final class AppSpacing {
  /// The base unit. Everything below is a multiple of it.
  static const double base = 4;

  /// 4px — the tightest gap, between a label and its value.
  static const double xs = 4;

  /// 8px — inside a chip, between an icon and its text.
  static const double sm = 8;

  /// 16px — between related cards, and card inner padding.
  static const double md = 16;

  /// 24px — inside large containers.
  static const double lg = 24;

  /// 32px — between major sections.
  static const double xl = 32;

  /// 20px side margin on mobile: the "frame" the design asks for. Deliberately
  /// off the 4px grid's usual 16/24 pair, and deliberately kept.
  static const double screenMargin = 20;

  /// 12px gutter between columns on mobile.
  static const double gutter = 12;

  /// Minimum interactive size. The design's component notes suggest a 24px
  /// checkbox, which its own safe-area rule contradicts — a 24px tap target is
  /// below every platform guideline. The mockups draw it far larger, and this
  /// is the floor everything tappable respects.
  static const double minTapTarget = 48;
}

/// Corner radii from the same file, in logical pixels.
///
/// The design's shape language is "significant roundedness to appear friendly",
/// including on checkboxes — squares with soft corners rather than circles, so
/// the geometry stays consistent.
abstract final class AppRadius {
  /// 4px.
  static const double sm = 4;

  /// 8px — the default.
  static const double base = 8;

  /// 12px.
  static const double md = 12;

  /// 16px — standard cards, and the habit checkbox.
  static const double lg = 16;

  /// 24px — bottom sheets and primary dashboards.
  static const double xl = 24;

  /// Pill shape, for frequency chips.
  static const double full = 999;
}

/// The two ambient shadows the design defines.
///
/// Values live here rather than inline so "level 1" and "level 2" stay two
/// things instead of drifting into five slightly different blurs.
abstract final class AppElevation {
  /// Cards: `0 4px 20px rgba(0,0,0,0.04)`.
  static const double cardBlur = 20;

  /// Vertical offset for [cardBlur].
  static const double cardOffsetY = 4;

  /// Opacity of the card shadow.
  static const double cardOpacity = 0.04;

  /// Floating elements: `0 8px 24px rgba(0,0,0,0.08)`.
  static const double floatingBlur = 24;

  /// Vertical offset for [floatingBlur].
  static const double floatingOffsetY = 8;

  /// Opacity of the floating shadow.
  static const double floatingOpacity = 0.08;

  /// How far a card scales down while pressed, for the "sink" the design asks
  /// for.
  static const double pressedScale = 0.98;
}
