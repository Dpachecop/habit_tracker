import 'package:fpdart/fpdart.dart';

import '../../domain/datasources/entries_datasource.dart';
import '../../domain/entities/date_only.dart';
import '../../domain/entities/date_period.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_entry.dart';
import '../../domain/entities/habit_schedule.dart';
import '../../domain/failures/failure.dart';
import '../../domain/repositories/entries_repository.dart';
import '../../domain/services/habit_completion_policy.dart';
import '../errors/guard.dart';

/// The entries repository, and the place where §3.5 is actually enforced.
///
/// Writing a check-in is not a plain insert. `HabitCompletionPolicy` gets the
/// final word first, so a caller that ignores the disabled button — a bug, a
/// stale UI, a future background job — still cannot record a day the user did
/// not earn. The button being disabled is a courtesy; this is the rule.
final class EntriesRepositoryImpl implements EntriesRepository {
  /// Wraps [datasource]. [clock] stamps `completedAt` and exists so tests do
  /// not depend on the wall clock.
  EntriesRepositoryImpl(this._datasource, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final EntriesDatasource _datasource;
  final DateTime Function() _clock;

  @override
  Stream<Either<Failure, List<HabitEntry>>> watchEntriesOn(DateOnly date) =>
      Guard.stream(_datasource.watchEntriesOn(date));

  @override
  Stream<Either<Failure, List<HabitEntry>>> watchEntries({
    DateOnly? from,
    DateOnly? to,
  }) => Guard.stream(_datasource.watchEntries(from: from, to: to));

  @override
  Stream<Either<Failure, List<HabitEntry>>> watchEntriesForHabit(
    String habitId, {
    DateOnly? from,
    DateOnly? to,
  }) => Guard.stream(
    _datasource.watchEntriesForHabit(habitId, from: from, to: to),
  );

  @override
  Future<Either<Failure, List<HabitEntry>>> entriesForHabit(
    String habitId, {
    DateOnly? from,
    DateOnly? to,
  }) => Guard.future(
    () => _datasource.entriesForHabit(habitId, from: from, to: to),
  );

  @override
  Future<Either<Failure, HabitEntry>> complete({
    required Habit habit,
    required DateOnly date,
    required DateOnly today,
  }) => Guard.futureEither(() async {
    final (DateOnly from, DateOnly to) = _relevantWindow(habit, date);
    final List<HabitEntry> existing = await _datasource.entriesForHabit(
      habit.id,
      from: from,
      to: to,
    );

    final Failure? refusal =
        HabitCompletionPolicy.ensureCanComplete(
          habit: habit,
          entries: existing,
          date: date,
          today: today,
        ).getLeft().toNullable();
    if (refusal != null) return Left<Failure, HabitEntry>(refusal);

    final HabitEntry entry = HabitEntry.on(habit.id, date, clock: _clock());
    await _datasource.putEntry(entry);
    return Right<Failure, HabitEntry>(entry);
  });

  @override
  Future<Either<Failure, Unit>> uncomplete({
    required Habit habit,
    required DateOnly date,
  }) => Guard.futureEither(() async {
    final Either<Failure, Unit> verdict =
        HabitCompletionPolicy.ensureCanUncomplete(habit: habit);
    if (verdict.isLeft()) return verdict;

    await _datasource.deleteEntry(habit.id, date);
    return const Right<Failure, Unit>(unit);
  });

  /// The span of entries the policy needs in order to judge [date].
  ///
  /// Only as much as the rule actually reads, because this is a network round
  /// trip on every tap. Mode A needs one day — is it already checked? Mode B
  /// needs the whole period, since the quota counts across it.
  (DateOnly, DateOnly) _relevantWindow(Habit habit, DateOnly date) {
    return switch (habit.scheduleOn(date)) {
      SpecificWeekdays() => (date, date),
      final TimesPerPeriod schedule => () {
        final DatePeriod period = DatePeriod.containing(date, schedule.period);
        return (period.start, period.end);
      }(),
    };
  }
}
