import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/date_only.dart';
import '../../../domain/entities/date_period.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/habit_category.dart';
import '../../../domain/entities/habit_color_slot.dart';
import '../../../domain/entities/habit_entry.dart';
import '../../../domain/entities/habit_schedule.dart';
import '../../../domain/entities/schedule_version.dart';
import '../../../domain/entities/time_window.dart';
import '../../../domain/entities/weekday.dart';
import '../../../domain/failures/failure.dart';
import '../../../domain/repositories/entries_repository.dart';
import '../../../domain/repositories/habits_repository.dart';
import '../../../domain/services/schedule_change_policy.dart';
import 'habit_form_state.dart';

/// Drives the create/edit form.
///
/// A Cubit rather than a Bloc, per `ARCHITECTURE.md` §7: every interaction here
/// is "the user set this field to that value", so naming an event type for each
/// one would be ceremony without a payoff.
///
/// The two rules it exists to honour, both from §3.4:
///
/// - Editing a schedule **appends a version**; it never overwrites. That is
///   enforced by `Habit.appendScheduleVersion`, and this only decides the date.
/// - If the change makes the open period impossible, the user is **told before**
///   it is saved. Burning a streak silently is not acceptable.
class HabitFormCubit extends Cubit<HabitFormState> {
  /// Opens a blank form for a new habit.
  ///
  /// [suggestedColor] should be the next unused palette slot — the declaration
  /// order of `HabitColorSlot` is what guarantees adjacent habits stay
  /// distinguishable, so picking in order matters.
  HabitFormCubit.create({
    required HabitsRepository habitsRepository,
    required EntriesRepository entriesRepository,
    HabitColorSlot suggestedColor = HabitColorSlot.blue,
    DateOnly Function()? today,
    String Function()? idFactory,
  }) : _habits = habitsRepository,
       _entries = entriesRepository,
       _todayOf = today ?? DateOnly.today,
       _newId = idFactory ?? _uuid,
       super(
         HabitFormState.create(
           today: (today ?? DateOnly.today)(),
           suggestedColor: suggestedColor,
         ),
       );

  /// Opens the form on an existing habit.
  HabitFormCubit.edit({
    required HabitsRepository habitsRepository,
    required EntriesRepository entriesRepository,
    required Habit habit,
    DateOnly Function()? today,
    String Function()? idFactory,
  }) : _habits = habitsRepository,
       _entries = entriesRepository,
       _todayOf = today ?? DateOnly.today,
       _newId = idFactory ?? _uuid,
       super(
         HabitFormState.edit(habit: habit, today: (today ?? DateOnly.today)()),
       );

  final HabitsRepository _habits;
  final EntriesRepository _entries;
  final DateOnly Function() _todayOf;
  final String Function() _newId;

  /// Client-side id generation, which is what lets a habit be created with no
  /// network and keep its identity once it syncs.
  static String _uuid() => const Uuid().v4();

  /// Sets the name.
  void nameChanged(String value) => emit(state.copyWith(name: value));

  /// Sets the category.
  void categoryChanged(HabitCategory value) =>
      emit(state.copyWith(category: value));

  /// Sets the palette slot.
  void colorChanged(HabitColorSlot value) =>
      emit(state.copyWith(colorSlot: value));

  /// Switches between the two schedule branches.
  ///
  /// Both branches' values are kept, so flipping back and forth never discards
  /// what the user already chose.
  void scheduleModeChanged(ScheduleMode value) =>
      emit(state.copyWith(scheduleMode: value));

  /// Adds or removes a weekday.
  void weekdayToggled(Weekday day) {
    final Set<Weekday> next = Set<Weekday>.of(state.weekdays);
    if (!next.remove(day)) next.add(day);
    emit(state.copyWith(weekdays: next));
  }

  /// Selects all seven days — the app's way of saying "daily".
  void everyDaySelected() => emit(state.copyWith(weekdays: Weekday.all));

  /// Sets the per-period target, clamped to what the period can hold.
  void timesChanged(int value) {
    final int clamped =
        value < 1 ? 1 : (value > state.maxTimes ? state.maxTimes : value);
    emit(state.copyWith(times: clamped));
  }

  /// Sets the period, re-clamping the target to the new ceiling.
  ///
  /// Moving from "5 a week" to "per month" is fine, but "30 a month" down to
  /// "per week" would leave an impossible 30-a-week behind.
  void periodChanged(SchedulePeriod value) {
    final HabitFormState next = state.copyWith(period: value);
    emit(
      next.times > next.maxTimes ? next.copyWith(times: next.maxTimes) : next,
    );
  }

  /// Turns the daily time window on or off.
  void allDayToggled({required bool isAllDay}) {
    if (isAllDay) {
      emit(state.copyWith(clearTimeWindow: true));
      return;
    }
    emit(
      state.copyWith(
        timeWindow:
            state.timeWindow ??
            TimeWindow.fromClock(
              startHour: 8,
              startMinute: 0,
              endHour: 9,
              endMinute: 0,
            ),
      ),
    );
  }

  /// Sets the time window.
  void timeWindowChanged(TimeWindow value) =>
      emit(state.copyWith(timeWindow: value));

  /// Sets the first day of the range.
  void startDateChanged(DateOnly value) =>
      emit(state.copyWith(rangeStart: value));

  /// Sets the last day of the range.
  void endDateChanged(DateOnly value) => emit(state.copyWith(rangeEnd: value));

  /// Makes the habit open-ended.
  void endDateCleared() => emit(state.copyWith(clearRangeEnd: true));

  /// Puts the §3.4 warning away without saving.
  void warningDismissed() => emit(state.copyWith(clearPendingWarning: true));

  /// Validates, checks the §3.4 warning, and writes.
  ///
  /// Stops at the warning the first time round: [confirmSave] is what gets past
  /// it. That two-step is the point — the user has to be shown the consequence
  /// before choosing it.
  Future<void> submit() async {
    if (!state.isValid) {
      emit(state.copyWith(showErrors: true));
      return;
    }

    final PeriodReachability? warning = await _reachability();
    if (warning != null && !warning.isReachable) {
      emit(state.copyWith(pendingWarning: warning));
      return;
    }

    await _write();
  }

  /// Saves despite the warning.
  Future<void> confirmSave() async {
    emit(state.copyWith(clearPendingWarning: true));
    await _write();
  }

  /// Archives the habit being edited.
  ///
  /// Archiving, never deleting: entries reference the habit, and removing it
  /// would tear a hole in every past report.
  Future<void> archive() async {
    final Habit? habit = state.original;
    if (habit == null) return;

    emit(state.copyWith(status: HabitFormStatus.saving, clearFailure: true));
    final Either<Failure, Unit> result = await _habits.archiveHabit(habit.id);

    emit(
      result.match(
        (Failure failure) =>
            state.copyWith(status: HabitFormStatus.failure, failure: failure),
        (_) => state.copyWith(status: HabitFormStatus.archived),
      ),
    );
  }

  /// Asks the domain whether the open period survives the change.
  ///
  /// Only relevant when editing an existing habit's schedule: a brand-new habit
  /// has no streak to burn, and an unchanged schedule changes nothing.
  Future<PeriodReachability?> _reachability() async {
    final Habit? habit = state.original;
    if (habit == null || !state.hasScheduleChanged) return null;

    final HabitSchedule schedule = state.schedule;
    if (schedule is! TimesPerPeriod) return null;

    final DatePeriod period = DatePeriod.containing(
      _todayOf(),
      schedule.period,
    );
    final Either<Failure, List<HabitEntry>> entries = await _entries
        .entriesForHabit(habit.id, from: period.start, to: period.end);

    return ScheduleChangePolicy.reachabilityAfterChange(
      habit: habit,
      newSchedule: schedule,
      // A failed read must not block the save. Worst case the warning does not
      // appear; refusing to save because a warning could not be computed would
      // be a far worse trade.
      entries: entries.getRight().getOrElse(() => const <HabitEntry>[]),
      today: _todayOf(),
    );
  }

  /// Builds the habit and writes it.
  Future<void> _write() async {
    emit(state.copyWith(status: HabitFormStatus.saving, clearFailure: true));

    final Habit habit = state.isEditing ? _updatedHabit() : _newHabit();
    final Either<Failure, Unit> result = await _habits.saveHabit(habit);

    emit(
      result.match(
        (Failure failure) =>
            state.copyWith(status: HabitFormStatus.failure, failure: failure),
        (_) => state.copyWith(status: HabitFormStatus.saved),
      ),
    );
  }

  /// Assembles a brand-new habit.
  Habit _newHabit() => Habit.create(
    id: _newId(),
    name: state.name.trim(),
    category: state.category,
    colorSlot: state.colorSlot,
    schedule: state.schedule,
    range: state.range,
    createdAt: DateTime.now().toUtc(),
    timeWindow: state.timeWindow,
  );

  /// Applies the edits to the existing habit.
  ///
  /// Everything except the schedule is a plain replacement. The schedule is the
  /// exception, and the whole reason `ScheduleVersion` exists.
  Habit _updatedHabit() {
    final Habit habit = state.original!;
    final Habit edited = habit.copyWith(
      name: state.name.trim(),
      category: state.category,
      colorSlot: state.colorSlot,
      range: state.range,
      timeWindow: state.timeWindow,
      clearTimeWindow: state.timeWindow == null,
      updatedAt: DateTime.now().toUtc(),
    );

    if (!state.hasScheduleChanged) return edited;

    return edited.appendScheduleVersion(
      ScheduleVersion(
        schedule: state.schedule,
        effectiveFrom: _effectiveFrom(state.schedule, habit),
      ),
      updatedAt: DateTime.now().toUtc(),
    );
  }

  /// When the new schedule starts applying.
  ///
  /// The policy decides — today for a target, tomorrow for named weekdays — but
  /// the result is floored at the newest version already on record. Without that
  /// floor, editing twice in one day could produce a date *earlier* than a
  /// version pending for tomorrow, and appending would throw. Flooring makes the
  /// later edit replace the pending one, which is what the user meant: the last
  /// thing they chose wins, and the past is still never rewritten.
  DateOnly _effectiveFrom(HabitSchedule schedule, Habit habit) {
    final DateOnly proposed = ScheduleChangePolicy.effectiveFromFor(
      schedule,
      _todayOf(),
    );
    final DateOnly newest = habit.scheduleHistory.last.effectiveFrom;
    return proposed < newest ? newest : proposed;
  }
}
