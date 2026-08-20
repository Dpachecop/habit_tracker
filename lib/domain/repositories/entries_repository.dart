import 'package:fpdart/fpdart.dart';

import '../entities/date_only.dart';
import '../entities/habit.dart';
import '../entities/habit_entry.dart';
import '../failures/failure.dart';

/// What the app can do with check-ins.
///
/// [complete] takes the whole [Habit], not just its id, because writing an
/// entry is not a plain insert: the no-over-completion rule has to be checked
/// first, and that needs the habit's schedule history
/// (`ARCHITECTURE.md` §3.5). The repository is the enforcement point, so a
/// caller that skips the disabled button still cannot write an illegal entry.
abstract interface class EntriesRepository {
  /// Watches every habit's entries for one day — what the home screen needs to
  /// know which cards are already checked.
  Stream<Either<Failure, List<HabitEntry>>> watchEntriesOn(DateOnly date);

  /// Watches every habit's entries inside a date window.
  ///
  /// What the home screen subscribes to: the streak of each card is derived from
  /// history, so today's entries alone are not enough. One windowed stream for
  /// the whole list rather than one per habit.
  Stream<Either<Failure, List<HabitEntry>>> watchEntries({
    DateOnly? from,
    DateOnly? to,
  });

  /// Watches one habit's entries in an optional window, for the heatmap and the
  /// reports.
  Stream<Either<Failure, List<HabitEntry>>> watchEntriesForHabit(
    String habitId, {
    DateOnly? from,
    DateOnly? to,
  });

  /// Reads one habit's entries in an optional window.
  Future<Either<Failure, List<HabitEntry>>> entriesForHabit(
    String habitId, {
    DateOnly? from,
    DateOnly? to,
  });

  /// Records [habit] as done on [date], if the domain allows it.
  ///
  /// Returns `ValidationFailure` with a `completion.*` code when it does not —
  /// the day is not scheduled, the period's quota is full, the date is in the
  /// future, and so on.
  Future<Either<Failure, HabitEntry>> complete({
    required Habit habit,
    required DateOnly date,
    required DateOnly today,
  });

  /// Removes the check-in for [date], undoing a mistap.
  ///
  /// Allowed for past days too: it can only ever shorten a streak, never forge
  /// one.
  Future<Either<Failure, Unit>> uncomplete({
    required Habit habit,
    required DateOnly date,
  });
}
