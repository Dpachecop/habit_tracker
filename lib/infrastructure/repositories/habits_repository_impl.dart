import 'package:fpdart/fpdart.dart';

import '../../domain/datasources/habits_datasource.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/schedule_version.dart';
import '../../domain/failures/failure.dart';
import '../../domain/repositories/habits_repository.dart';
import '../errors/guard.dart';

/// The habits repository over any [HabitsDatasource].
///
/// It knows nothing about Firestore: it takes the contract, catches whatever
/// the implementation throws and hands back `Either`. Swapping the datasource
/// for a local database changes nothing here.
final class HabitsRepositoryImpl implements HabitsRepository {
  /// Wraps [datasource].
  const HabitsRepositoryImpl(this._datasource);

  final HabitsDatasource _datasource;

  @override
  Stream<Either<Failure, List<Habit>>> watchHabits({
    bool includeArchived = false,
  }) => Guard.stream(_datasource.watchHabits(includeArchived: includeArchived));

  @override
  Future<Either<Failure, Habit>> getHabit(String id) =>
      Guard.futureEither(() async {
        final Habit? habit = await _datasource.findHabit(id);
        // Absence is a expected outcome with its own failure, not an error the
        // datasource should have thrown for.
        if (habit == null) return const Left<Failure, Habit>(NotFoundFailure());
        return Right<Failure, Habit>(habit);
      });

  @override
  Future<Either<Failure, Unit>> saveHabit(Habit habit) =>
      Guard.future(() async {
        await _datasource.upsertHabit(habit);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> changeSchedule(
    String habitId,
    ScheduleVersion version,
  ) => Guard.futureEither(() async {
    final Habit? habit = await _datasource.findHabit(habitId);
    if (habit == null) return const Left<Failure, Unit>(NotFoundFailure());
    // Read-modify-write through the entity, so §3.4's append rules — never
    // overwrite, never back-date — are enforced by `Habit` itself instead of
    // being restated here where they could drift.
    await _datasource.upsertHabit(habit.appendScheduleVersion(version));
    return const Right<Failure, Unit>(unit);
  });

  @override
  Future<Either<Failure, Unit>> archiveHabit(String id) =>
      Guard.future(() async {
        await _datasource.archiveHabit(id);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> restoreHabit(String id) =>
      Guard.future(() async {
        await _datasource.restoreHabit(id);
        return unit;
      });
}
