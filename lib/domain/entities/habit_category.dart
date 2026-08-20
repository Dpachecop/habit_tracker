/// What area of life a habit belongs to.
///
/// A closed enum rather than free text: categories are used to group and filter
/// in the reports, and user-typed labels would fragment into "Gym", "gym" and
/// "GYM" within a week. The trade-off is that adding one is a code change —
/// acceptable for a personal app, and reversible if the owner ever asks for
/// custom categories (that would become an entity with an id and a name).
///
/// Names are identifiers, not UI text. Presentation maps each value to a
/// localized label the same way it maps a `HabitColorSlot` to a color.
enum HabitCategory {
  /// Sleep, diet, medication, medical routine.
  health,

  /// Training, sport, movement.
  fitness,

  /// Meditation, journaling, therapy, anything mental.
  mind,

  /// Studying, reading, practising a skill.
  learning,

  /// Job and career.
  work,

  /// Saving, budgeting, expense tracking.
  finance,

  /// Family, friends, relationships.
  social,

  /// Chores, tidying, maintenance.
  home,

  /// Making things — writing, music, drawing.
  creativity,

  /// Anything that does not fit above.
  other,
}
