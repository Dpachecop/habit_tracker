import 'package:flutter/material.dart';

import '../../domain/entities/habit_category.dart';

/// The glyph shown in the badge on a habit card.
///
/// Derived from the habit's **category** rather than stored per habit, which
/// keeps `Habit` free of a field the domain has no rules about and spares the
/// form a picker. The trade-off is bluntness: a habit called "Drink water"
/// filed under Health gets a heart, not a droplet. If that turns out to matter,
/// a nullable `icon` on `Habit` overriding this map is an additive change that
/// breaks nothing.
///
/// Outlined weights throughout, to match the line-drawn glyphs in the mockups.
/// Lives beside `HabitPalette` because it does the same kind of job: resolving a
/// domain enum into something only presentation is allowed to know about.
abstract final class CategoryIcons {
  /// The icon for [category].
  ///
  /// Exhaustive on purpose — no `default` branch. A new category then becomes a
  /// compile error here, which is the reminder that it needs a glyph as well as
  /// a translation.
  static IconData of(HabitCategory category) => switch (category) {
    HabitCategory.health => Icons.favorite_outline_rounded,
    HabitCategory.fitness => Icons.fitness_center_rounded,
    HabitCategory.mind => Icons.self_improvement_rounded,
    HabitCategory.learning => Icons.menu_book_rounded,
    HabitCategory.work => Icons.work_outline_rounded,
    HabitCategory.finance => Icons.savings_outlined,
    HabitCategory.social => Icons.people_outline_rounded,
    HabitCategory.home => Icons.home_outlined,
    HabitCategory.creativity => Icons.brush_outlined,
    HabitCategory.other => Icons.bookmark_outline_rounded,
  };
}
