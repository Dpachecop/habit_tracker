import 'package:fpdart/fpdart.dart';

import '../entities/habit.dart';
import '../entities/schedule_version.dart';
import '../failures/failure.dart';

/// What the app can do with habits.
///
/// Everything returns `Either<Failure, T>`: an error is part of the signature,
/// not an exception a caller can forget to handle (`ARCHITECTURE.md` §5).
abstract interface class HabitsRepository {
  /// Watches the habit list.
  ///
  /// Errors arrive inside the stream rather than terminating it, so a transient
  /// failure does not leave the home screen permanently unsubscribed.
  Stream<Either<Failure, List<Habit>>> watchHabits({
    bool includeArchived = false,
  });

  /// Reads one habit. `NotFoundFailure` when it does not exist.
  Future<Either<Failure, Habit>> getHabit(String id);

  /// Creates or updates a habit.
  ///
  /// Note this cannot change the schedule safely on its own — use
  /// [changeSchedule], which appends a version instead of overwriting.
  Future<Either<Failure, Unit>> saveHabit(Habit habit);

  /// Appends a new schedule version to a habit (`ARCHITECTURE.md` §3.4).
  ///
  /// A separate operation rather than part of [saveHabit] because it is the one
  /// edit that must never overwrite: a streak earned under the old rules has to
  /// survive the change, and it only can if the old version stays on record.
  Future<Either<Failure, Unit>> changeSchedule(
    String habitId,
    ScheduleVersion version,
  );

  /// Archives a habit. Never deletes — that would destroy its history.
  Future<Either<Failure, Unit>> archiveHabit(String id);

  /// Brings an archived habit back into the active list.
  Future<Either<Failure, Unit>> restoreHabit(String id);
}
