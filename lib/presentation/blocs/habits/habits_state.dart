import 'package:equatable/equatable.dart';

import '../../../domain/entities/date_only.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/streak.dart';
import '../../../domain/failures/failure.dart';
import '../../../domain/services/habit_completion_policy.dart';

/// How far the state has got.
enum HabitsStatus {
  /// Nothing requested yet.
  initial,

  /// Subscribed, first emission not in yet.
  loading,

  /// Showing data. The list may still be empty — that is a valid ready state,
  /// not a loading one, and the difference is what lets the empty state appear.
  ready,

  /// The subscription failed before delivering anything.
  failure,
}

/// One habit, plus everything the card needs to draw itself.
///
/// Assembled in the bloc rather than in the widget so the rules stay in one
/// place: the streak comes from `StreakCalculator`, the enabled/disabled verdict
/// from `HabitCompletionPolicy`, and the card only paints what it is handed. A
/// widget that recomputed either would be a second implementation of the rules,
/// and the two would eventually disagree.
final class HabitSummary extends Equatable {
  /// Bundles a habit with its derived figures.
  const HabitSummary({
    required this.habit,
    required this.streak,
    required this.availability,
    required this.isCompletedToday,
  });

  /// The habit itself.
  final Habit habit;

  /// Derived streak. Never read from storage.
  final Streak streak;

  /// Whether today can be checked, and why not when it cannot. Carries the
  /// period counters that the card renders as "2/3 this week".
  final CompletionAvailability availability;

  /// Whether today already has an entry.
  final bool isCompletedToday;

  /// Whether tapping the check would do something right now.
  ///
  /// This is also the definition of "left to complete today": the domain already
  /// decides it, so the header count and the checkbox cannot disagree.
  bool get isActionable => availability.isAllowed;

  @override
  List<Object?> get props => <Object?>[
    habit,
    streak,
    availability,
    isCompletedToday,
  ];
}

/// What the home screen renders.
///
/// One class with a [status] rather than a sealed union of states, because the
/// screen frequently needs to show a list *and* an error at once — a rejected
/// tap while the list is perfectly fine. A union would force either dropping the
/// list or duplicating it into an error case.
final class HabitsState extends Equatable {
  /// Creates a state. Prefer [HabitsState.initial] outside the bloc.
  const HabitsState({
    required this.status,
    required this.summaries,
    required this.today,
    this.loadFailure,
    this.actionFailure,
    this.actionSeq = 0,
  });

  /// The state before anything is requested.
  const HabitsState.initial(this.today)
    : status = HabitsStatus.initial,
      summaries = const <HabitSummary>[],
      loadFailure = null,
      actionFailure = null,
      actionSeq = 0;

  /// How far loading has got.
  final HabitsStatus status;

  /// The cards, in the repository's order.
  final List<HabitSummary> summaries;

  /// The day everything is computed against. Held in the state rather than read
  /// from the clock by widgets, so a test can fix it and every card agrees.
  final DateOnly today;

  /// Why the list could not be loaded. Rendered as a banner or a retry.
  final Failure? loadFailure;

  /// Why the last tap was refused. Rendered as a transient message.
  final Failure? actionFailure;

  /// Increments with every refused tap.
  ///
  /// Without it, two identical refusals in a row would produce two equal states
  /// and the second one would never reach a `BlocListener` — the user would tap,
  /// be refused, and see nothing.
  final int actionSeq;

  /// Habits that could be checked off right now.
  int get pendingToday =>
      summaries.where((HabitSummary summary) => summary.isActionable).length;

  /// Habits already checked off today.
  int get completedToday =>
      summaries
          .where((HabitSummary summary) => summary.isCompletedToday)
          .length;

  /// Whether today asks anything of the user at all.
  ///
  /// Distinguishes "you are done" from "nothing was due" — telling someone
  /// "well done, nothing left" on a day their habits never fell on would be
  /// congratulating them for the calendar.
  bool get anythingDueToday => pendingToday > 0 || completedToday > 0;

  /// Whether the user has no habits at all.
  bool get isEmpty => status == HabitsStatus.ready && summaries.isEmpty;

  /// Returns a copy with the fields given replaced.
  ///
  /// [clearActionFailure] exists because passing `null` cannot be told from
  /// omitting it, and a refusal has to be clearable.
  HabitsState copyWith({
    HabitsStatus? status,
    List<HabitSummary>? summaries,
    DateOnly? today,
    Failure? loadFailure,
    bool clearLoadFailure = false,
    Failure? actionFailure,
    bool clearActionFailure = false,
    int? actionSeq,
  }) => HabitsState(
    status: status ?? this.status,
    summaries: summaries ?? this.summaries,
    today: today ?? this.today,
    loadFailure: clearLoadFailure ? null : (loadFailure ?? this.loadFailure),
    actionFailure:
        clearActionFailure ? null : (actionFailure ?? this.actionFailure),
    actionSeq: actionSeq ?? this.actionSeq,
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    summaries,
    today,
    loadFailure,
    actionFailure,
    actionSeq,
  ];
}
