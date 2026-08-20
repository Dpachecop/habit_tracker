import 'package:equatable/equatable.dart';

import '../../../domain/entities/habit.dart';
import '../../../domain/entities/habit_entry.dart';
import '../../../domain/failures/failure.dart';

/// Everything that can happen to the habit list.
sealed class HabitsEvent extends Equatable {
  /// Const so events stay cheap values.
  const HabitsEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Start listening to habits and to the entry history behind their streaks.
///
/// Dispatched once, when the screen mounts. Everything after that arrives
/// through the streams, which is why there is no "refresh" event: a pull to
/// refresh would only re-read what Firestore is already pushing.
final class HabitsSubscriptionRequested extends HabitsEvent {
  /// Creates the event.
  const HabitsSubscriptionRequested();
}

/// The user tapped a habit's check for today.
///
/// One event for both directions. Which way it goes depends on whether today
/// already has an entry, and the bloc knows that — making the widget decide
/// would let a stale frame send the wrong intent.
final class HabitCheckToggled extends HabitsEvent {
  /// [habit] is the whole entity because the completion rules need its schedule
  /// history, not just its id.
  const HabitCheckToggled(this.habit);

  /// The habit whose check was tapped.
  final Habit habit;

  @override
  List<Object?> get props => <Object?>[habit];
}

/// Internal: the habit list changed.
final class HabitsListUpdated extends HabitsEvent {
  /// [habits] is the new list, or [failure] explains why there is none.
  const HabitsListUpdated({this.habits, this.failure});

  /// The new list, when the emission succeeded.
  final List<Habit>? habits;

  /// The failure, when it did not.
  final Failure? failure;

  @override
  List<Object?> get props => <Object?>[habits, failure];
}

/// Internal: the entry history changed.
///
/// Separate from [HabitsListUpdated] because the two arrive on independent
/// streams and either can move without the other. The bloc holds the latest of
/// each and recomputes from both.
final class HabitsEntriesUpdated extends HabitsEvent {
  /// [entries] is the new window, or [failure] explains why there is none.
  const HabitsEntriesUpdated({this.entries, this.failure});

  /// The new entries, when the emission succeeded.
  final List<HabitEntry>? entries;

  /// The failure, when it did not.
  final Failure? failure;

  @override
  List<Object?> get props => <Object?>[entries, failure];
}
