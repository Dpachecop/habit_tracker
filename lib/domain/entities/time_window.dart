import 'package:equatable/equatable.dart';

/// The slot of the day a habit is meant to happen in — "the gym, 7:00 to 8:30".
///
/// A `null` window on a `Habit` means all day. It is a display and reminder
/// concern only: the streak engine never looks at it, because a habit done at
/// 23:00 instead of 07:00 was still done that day. Modelling it as a value
/// object rather than two loose ints keeps that boundary honest.
///
/// Stored as minutes past local midnight instead of Flutter's `TimeOfDay`,
/// which lives in `dart:ui` and would drag the framework into the domain.
final class TimeWindow extends Equatable {
  /// Throws [ArgumentError] on out-of-day values or on an end that does not
  /// follow its start.
  ///
  /// Windows that wrap past midnight are not supported: they would make "which
  /// day is this?" ambiguous, and no habit in this app needs one yet. Splitting
  /// such a window in two is the workaround if it ever comes up.
  TimeWindow({required this.startMinuteOfDay, required this.endMinuteOfDay}) {
    if (startMinuteOfDay < 0 || startMinuteOfDay >= _minutesPerDay) {
      throw ArgumentError.value(
        startMinuteOfDay,
        'startMinuteOfDay',
        'must be within a day',
      );
    }
    if (endMinuteOfDay <= startMinuteOfDay || endMinuteOfDay > _minutesPerDay) {
      throw ArgumentError.value(
        endMinuteOfDay,
        'endMinuteOfDay',
        'must follow the start and stay within the day',
      );
    }
  }

  /// Builds a window from wall-clock hours and minutes, which is how both the
  /// form and the tests think about it.
  factory TimeWindow.fromClock({
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) => TimeWindow(
    startMinuteOfDay: startHour * 60 + startMinute,
    endMinuteOfDay: endHour * 60 + endMinute,
  );

  static const int _minutesPerDay = 24 * 60;

  /// Minutes past local midnight the window opens at.
  final int startMinuteOfDay;

  /// Minutes past local midnight the window closes at, exclusive.
  final int endMinuteOfDay;

  /// Hour the window opens at, 0-23.
  int get startHour => startMinuteOfDay ~/ 60;

  /// Minute within [startHour] the window opens at.
  int get startMinute => startMinuteOfDay % 60;

  /// Hour the window closes at, 0-24.
  int get endHour => endMinuteOfDay ~/ 60;

  /// Minute within [endHour] the window closes at.
  int get endMinute => endMinuteOfDay % 60;

  /// How long the window lasts.
  Duration get duration => Duration(minutes: endMinuteOfDay - startMinuteOfDay);

  @override
  List<Object?> get props => <Object?>[startMinuteOfDay, endMinuteOfDay];
}
