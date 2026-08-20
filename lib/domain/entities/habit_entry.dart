import 'package:equatable/equatable.dart';

import 'date_only.dart';

/// Proof that a habit was done on a given day.
///
/// There is no `completed` flag: the entry existing *is* the completion, and
/// unchecking deletes it. A boolean would let a `false` row and a missing row
/// mean the same thing in two different ways, and the streak engine would have
/// to handle both.
final class HabitEntry extends Equatable {
  /// [completedAt] must be UTC — see the field's own note.
  HabitEntry({
    required this.habitId,
    required this.date,
    required this.completedAt,
  }) {
    if (!completedAt.isUtc) {
      throw ArgumentError.value(
        completedAt,
        'completedAt',
        'must be UTC; the local day belongs in `date`',
      );
    }
  }

  /// Builds an entry stamped at [clock], defaulting to now.
  ///
  /// The parameter is what makes entry creation testable without freezing the
  /// system clock.
  factory HabitEntry.on(String habitId, DateOnly date, {DateTime? clock}) =>
      HabitEntry(
        habitId: habitId,
        date: date,
        completedAt: (clock ?? DateTime.now()).toUtc(),
      );

  /// The habit this check-in belongs to.
  final String habitId;

  /// The local calendar day that was completed. This, not [completedAt], is
  /// what every streak rule reads.
  final DateOnly date;

  /// When the check-in was recorded, in UTC.
  ///
  /// Audit only — useful for "you usually do this at night", never for deciding
  /// which day it counts for. UTC because an instant with a local offset is
  /// meaningless once the device changes zone.
  final DateTime completedAt;

  /// The Firestore document id: `{habitId}_{yyyy-MM-dd}`.
  ///
  /// Deterministic on purpose. It gives uniqueness per habit and day for free,
  /// and makes checking the same day twice an idempotent write rather than a
  /// duplicate row (`ARCHITECTURE.md` §3.3).
  String get documentId => '${habitId}_${date.toIso8601()}';

  /// Equality ignores [completedAt]: two check-ins for the same habit and day
  /// are the same entry, whatever second they were tapped at. Anything else
  /// would make a re-sync from Firestore look like a change.
  @override
  List<Object?> get props => <Object?>[habitId, date];
}
