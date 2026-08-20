import '../entities/habit.dart';

/// Raw access to stored habits.
///
/// Datasources **throw**; repositories catch and translate into `Failure`s.
/// Splitting it that way keeps the try/catch in exactly one layer instead of
/// smeared across both.
///
/// The contract lives in the domain so that the Firestore implementation is
/// swappable for a local database without touching a single line above it.
abstract interface class HabitsDatasource {
  /// Emits the habit list and every later change to it.
  ///
  /// A stream, not a one-shot read: the home screen has to reflect an edit made
  /// on another device without anyone pulling to refresh.
  Stream<List<Habit>> watchHabits({bool includeArchived = false});

  /// Reads one habit, or `null` when there is none with that id.
  Future<Habit?> findHabit(String id);

  /// Creates or replaces a habit. The id comes from the client, so create and
  /// update are the same write.
  Future<void> upsertHabit(Habit habit);

  /// Flags a habit as archived.
  ///
  /// There is no delete in this contract on purpose — entries reference the
  /// habit and removing it would tear a hole in the history.
  Future<void> archiveHabit(String id);

  /// Clears the archived flag, putting the habit back in the active list.
  Future<void> restoreHabit(String id);
}
