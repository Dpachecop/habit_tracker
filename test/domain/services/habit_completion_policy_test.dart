import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:habit_tracker/domain/entities/date_only.dart';
import 'package:habit_tracker/domain/entities/habit.dart';
import 'package:habit_tracker/domain/entities/habit_entry.dart';
import 'package:habit_tracker/domain/entities/habit_schedule.dart';
import 'package:habit_tracker/domain/entities/schedule_version.dart';
import 'package:habit_tracker/domain/entities/weekday.dart';
import 'package:habit_tracker/domain/failures/failure.dart';
import 'package:habit_tracker/domain/services/habit_completion_policy.dart';

import '../fixtures.dart';

void main() {
  /// Asks the policy about a day. Defaults [today] to the day being checked,
  /// which is the normal case — the user tapping today's checkbox.
  CompletionAvailability checkOn(
    Habit habit,
    DateOnly date, {
    List<HabitEntry> entries = const <HabitEntry>[],
    DateOnly? today,
  }) => HabitCompletionPolicy.check(
    habit: habit,
    entries: entries,
    date: date,
    today: today ?? date,
  );

  /// The failure code of a refused result, or `null` when it was allowed.
  String? codeOf(Either<Failure, Unit> result) =>
      result.fold((Failure failure) => failure.code, (_) => null);

  group('mode A — only scheduled days can be checked', () {
    final Habit monWedSat = weekdayHabit(
      days: <Weekday>{Weekday.monday, Weekday.wednesday, Weekday.saturday},
      start: d(2026, 8, 1),
    );

    test('allows a scheduled day', () {
      expect(checkOn(monWedSat, d(2026, 8, 3)).isAllowed, isTrue);
    });

    test('refuses a day the habit is not due on', () {
      // §3.5: the goal was three named days. Tuesday is not one of them, and
      // doing it anyway is a different goal.
      final CompletionAvailability result = checkOn(monWedSat, d(2026, 8, 4));
      expect(result.isAllowed, isFalse);
      expect(result.reason, CompletionBlockReason.notScheduled);
    });

    test('reports no quota numbers — there is no quota in this mode', () {
      final CompletionAvailability result = checkOn(monWedSat, d(2026, 8, 3));
      expect(result.periodTarget, isNull);
      expect(result.completedInPeriod, isNull);
    });
  });

  group('mode B — the period quota caps it', () {
    final Habit threeAWeek = timesHabit(times: 3, start: d(2026, 8, 3));

    test('allows any day while there is room, and reports the count', () {
      final CompletionAvailability result = checkOn(
        threeAWeek,
        d(2026, 8, 6),
        entries: entriesOn(<DateOnly>[d(2026, 8, 3)]),
      );

      expect(result.isAllowed, isTrue);
      expect(result.completedInPeriod, 1);
      expect(result.periodTarget, 3);
    });

    test('refuses once the quota is full', () {
      final CompletionAvailability result = checkOn(
        threeAWeek,
        d(2026, 8, 6),
        entries: entriesOn(datesFrom(d(2026, 8, 3), d(2026, 8, 5))),
      );

      expect(result.isAllowed, isFalse);
      expect(result.reason, CompletionBlockReason.quotaReached);
      // The card renders these as "3/3 this week".
      expect(result.completedInPeriod, 3);
      expect(result.periodTarget, 3);
    });

    test('counts only the period the day belongs to', () {
      // Last week's three must not fill this week's quota.
      final Habit habit = timesHabit(times: 3, start: d(2026, 7, 27));
      final CompletionAvailability result = checkOn(
        habit,
        d(2026, 8, 6),
        entries: entriesOn(datesFrom(d(2026, 7, 27), d(2026, 7, 29))),
      );

      expect(result.isAllowed, isTrue);
      expect(result.completedInPeriod, 0);
    });
  });

  group('the quota follows the versioned target — §3.4', () {
    test('raising it mid-week makes room again', () {
      final Habit habit = versionedHabit(
        start: d(2026, 8, 3),
        versions: <ScheduleVersion>[
          ScheduleVersion(
            schedule: TimesPerPeriod(times: 3, period: SchedulePeriod.week),
            effectiveFrom: d(2026, 8, 3),
          ),
          ScheduleVersion(
            schedule: TimesPerPeriod(times: 5, period: SchedulePeriod.week),
            effectiveFrom: d(2026, 8, 5),
          ),
        ],
      );
      final CompletionAvailability result = checkOn(
        habit,
        d(2026, 8, 6),
        entries: entriesOn(datesFrom(d(2026, 8, 3), d(2026, 8, 5))),
      );

      expect(result.isAllowed, isTrue);
      expect(result.completedInPeriod, 3);
      expect(result.periodTarget, 5);
    });

    test(
      'lowering it mid-week does not make the days already done illegal',
      () {
        // The week keeps the higher target, so five entries stay valid; a sixth
        // is still refused.
        final Habit habit = versionedHabit(
          start: d(2026, 8, 3),
          versions: <ScheduleVersion>[
            ScheduleVersion(
              schedule: TimesPerPeriod(times: 5, period: SchedulePeriod.week),
              effectiveFrom: d(2026, 8, 3),
            ),
            ScheduleVersion(
              schedule: TimesPerPeriod(times: 3, period: SchedulePeriod.week),
              effectiveFrom: d(2026, 8, 5),
            ),
          ],
        );
        final CompletionAvailability result = checkOn(
          habit,
          d(2026, 8, 8),
          entries: entriesOn(datesFrom(d(2026, 8, 3), d(2026, 8, 7))),
        );

        expect(result.isAllowed, isFalse);
        expect(result.reason, CompletionBlockReason.quotaReached);
        expect(result.periodTarget, 5);
      },
    );
  });

  group('guards that apply to both modes', () {
    test('refuses a day in the future', () {
      expect(
        checkOn(
          weekdayHabit(start: d(2026, 8, 1)),
          d(2026, 8, 7),
          today: d(2026, 8, 6),
        ).reason,
        CompletionBlockReason.futureDate,
      );
    });

    test('refuses a day outside the range, at either end', () {
      final Habit bounded = weekdayHabit(
        start: d(2026, 8, 3),
        end: d(2026, 8, 9),
      );
      expect(
        checkOn(bounded, d(2026, 8, 2), today: d(2026, 8, 12)).reason,
        CompletionBlockReason.outsideRange,
      );
      expect(
        checkOn(bounded, d(2026, 8, 10), today: d(2026, 8, 12)).reason,
        CompletionBlockReason.outsideRange,
      );
    });

    test('refuses anything on an archived habit', () {
      final Habit archived = weekdayHabit(
        start: d(2026, 8, 1),
        isArchived: true,
      );
      expect(
        checkOn(archived, d(2026, 8, 6)).reason,
        CompletionBlockReason.archived,
      );
    });

    test('refuses a day that is already checked', () {
      expect(
        checkOn(
          weekdayHabit(start: d(2026, 8, 1)),
          d(2026, 8, 6),
          entries: entriesOn(<DateOnly>[d(2026, 8, 6)]),
        ).reason,
        CompletionBlockReason.alreadyCompleted,
      );
    });

    test('says already-checked, not unscheduled, for a day done under old '
        'rules', () {
      // The schedule changed and that day is no longer due. It was legitimately
      // completed then, so the honest answer is "already done".
      final Habit habit = versionedHabit(
        start: d(2026, 8, 1),
        versions: <ScheduleVersion>[
          ScheduleVersion(
            schedule: SpecificWeekdays.daily(),
            effectiveFrom: d(2026, 8, 1),
          ),
          ScheduleVersion(
            schedule: SpecificWeekdays(<Weekday>{Weekday.monday}),
            effectiveFrom: d(2026, 8, 6),
          ),
        ],
      );
      expect(
        checkOn(
          habit,
          d(2026, 8, 6),
          entries: entriesOn(<DateOnly>[d(2026, 8, 6)]),
        ).reason,
        CompletionBlockReason.alreadyCompleted,
      );
    });

    test("ignores other habits' entries when counting the quota", () {
      final CompletionAvailability result = checkOn(
        timesHabit(times: 3, start: d(2026, 8, 3)),
        d(2026, 8, 6),
        entries: entriesOn(
          datesFrom(d(2026, 8, 3), d(2026, 8, 5)),
          habitId: 'someone-else',
        ),
      );

      expect(result.isAllowed, isTrue);
      expect(result.completedInPeriod, 0);
    });
  });

  group('ensureCanComplete', () {
    test('is a Right when the day is allowed', () {
      final Either<Failure, Unit> result =
          HabitCompletionPolicy.ensureCanComplete(
            habit: weekdayHabit(start: d(2026, 8, 1)),
            entries: const <HabitEntry>[],
            date: d(2026, 8, 6),
            today: d(2026, 8, 6),
          );

      expect(result.isRight(), isTrue);
    });

    test('is a ValidationFailure carrying the reason code', () {
      // This is the enforcement point: a client that ignores the disabled
      // button still cannot write the entry.
      final Either<Failure, Unit> result =
          HabitCompletionPolicy.ensureCanComplete(
            habit: timesHabit(times: 3, start: d(2026, 8, 3)),
            entries: entriesOn(datesFrom(d(2026, 8, 3), d(2026, 8, 5))),
            date: d(2026, 8, 6),
            today: d(2026, 8, 6),
          );

      expect(result.isLeft(), isTrue);
      expect(codeOf(result), FailureCodes.completionQuotaReached);
      result.fold(
        (Failure failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('expected a failure'),
      );
    });

    test('maps every block reason to a distinct code', () {
      final Set<String> codes =
          CompletionBlockReason.values
              .map((CompletionBlockReason reason) => reason.failureCode)
              .toSet();
      expect(codes.length, CompletionBlockReason.values.length);
    });
  });

  group('ensureCanUncomplete', () {
    test('allows undoing on a live habit', () {
      expect(
        HabitCompletionPolicy.ensureCanUncomplete(
          habit: weekdayHabit(start: d(2026, 8, 1)),
        ).isRight(),
        isTrue,
      );
    });

    test('refuses on an archived one, whose history is frozen', () {
      final Either<Failure, Unit> result =
          HabitCompletionPolicy.ensureCanUncomplete(
            habit: weekdayHabit(start: d(2026, 8, 1), isArchived: true),
          );

      expect(codeOf(result), FailureCodes.completionArchived);
    });
  });
}
