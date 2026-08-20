import 'package:equatable/equatable.dart';

import '../../../domain/entities/date_only.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/habit_entry.dart';
import '../../../domain/entities/streak.dart';
import '../../../domain/failures/failure.dart';

/// How far the detail screen has got.
enum HabitDetailStatus {
  /// Subscribed, nothing in yet.
  loading,

  /// Showing the habit.
  ready,

  /// Could not load it.
  failure,
}

/// Everything the habit detail screen shows.
///
/// It keeps the raw [entries] rather than pre-rendered grids: the screen draws
/// two views over the same history — a year-ish contribution grid and one month
/// at a time — and which month that is changes as the user pages. Projecting
/// both here would mean recomputing the grid every time the month arrow is
/// tapped, for no gain.
final class HabitDetailState extends Equatable {
  /// Creates a state.
  const HabitDetailState({
    required this.status,
    required this.today,
    required this.visibleMonth,
    this.habit,
    this.entries = const <HabitEntry>[],
    this.streak = Streak.empty,
    this.failure,
  });

  /// The state before anything has loaded, with the month set to today's.
  const HabitDetailState.loading(DateOnly today)
    : this(
        status: HabitDetailStatus.loading,
        today: today,
        visibleMonth: today,
      );

  /// How far loading has got.
  final HabitDetailStatus status;

  /// The habit, once it is in.
  final Habit? habit;

  /// Its whole check-in history.
  ///
  /// Unbounded on purpose, unlike the home screen's 400-day window. This is one
  /// habit rather than all of them, opened deliberately rather than on every
  /// launch, and the month arrows can walk back to any month — a window would
  /// mean the calendar quietly went blank past its edge.
  final List<HabitEntry> entries;

  /// Its streak. Derived over the full history here, so unlike the home
  /// screen's it is not truncated by a window.
  final Streak streak;

  /// The day everything is judged against.
  final DateOnly today;

  /// Any day inside the month the calendar is showing.
  final DateOnly visibleMonth;

  /// Why it could not be loaded.
  final Failure? failure;

  /// Whether the calendar is showing a month later than this one.
  ///
  /// Used to stop the forward arrow: there is nothing to see in the future, and
  /// letting someone page into 2031 one tap at a time is not navigation.
  bool get canGoForward =>
      visibleMonth.year < today.year ||
      (visibleMonth.year == today.year && visibleMonth.month < today.month);

  /// Returns a copy with the fields given replaced.
  HabitDetailState copyWith({
    HabitDetailStatus? status,
    Habit? habit,
    List<HabitEntry>? entries,
    Streak? streak,
    DateOnly? visibleMonth,
    Failure? failure,
    bool clearFailure = false,
  }) => HabitDetailState(
    status: status ?? this.status,
    habit: habit ?? this.habit,
    entries: entries ?? this.entries,
    streak: streak ?? this.streak,
    today: today,
    visibleMonth: visibleMonth ?? this.visibleMonth,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    habit,
    entries,
    streak,
    today,
    visibleMonth,
    failure,
  ];
}
