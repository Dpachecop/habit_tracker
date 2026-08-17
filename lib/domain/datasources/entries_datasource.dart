import '../entities/date_only.dart';
import '../entities/habit_entry.dart';

/// Raw access to stored check-ins.
///
/// Like `HabitsDatasource`, it throws and lets the repository translate.
///
/// The two query shapes below are why entries are stored in one flat
/// collection rather than nested under each habit (`ARCHITECTURE.md` §6.3):
/// the home screen wants every habit's entries for one day, the reports want
/// one habit's entries across a range. Flat serves both without a collection
/// group query.
abstract interface class EntriesDatasource {
  /// Emits every habit's entries for [date], and every later change to them.
  Stream<List<HabitEntry>> watchEntriesOn(DateOnly date);

  /// Emits every habit's entries inside a date window.
  ///
  /// The home screen's read: it needs enough history to derive a streak per
  /// habit, and one subscription over a window beats one subscription per habit.
  /// Callers bound the window — an unbounded read grows without limit.
  Stream<List<HabitEntry>> watchEntries({DateOnly? from, DateOnly? to});

  /// Emits one habit's entries within an optional date window.
  Stream<List<HabitEntry>> watchEntriesForHabit(
    String habitId, {
    DateOnly? from,
    DateOnly? to,
  });

  /// Reads one habit's entries within an optional date window.
  ///
  /// The one-shot counterpart to [watchEntriesForHabit], for the completion
  /// policy: before writing an entry the repository needs the period's current
  /// entries, and it should not have to subscribe to get them.
  Future<List<HabitEntry>> entriesForHabit(
    String habitId, {
    DateOnly? from,
    DateOnly? to,
  });

  /// Writes a check-in.
  ///
  /// Idempotent: the document id is `{habitId}_{yyyy-MM-dd}`, so writing the
  /// same day twice is one document either way.
  Future<void> putEntry(HabitEntry entry);

  /// Removes the check-in for a habit and day, if there is one.
  ///
  /// Unchecking deletes rather than flipping a flag — the entry's existence
  /// *is* the completion.
  Future<void> deleteEntry(String habitId, DateOnly date);
}
