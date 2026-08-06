import 'package:equatable/equatable.dart';

import 'date_only.dart';

/// The span of days a habit is alive for: a start, and an end that may never
/// come.
///
/// Most habits are open-ended ("meditate, from now on"), but a goal can also be
/// bounded ("train every day until the race on the 14th"). The streak engine
/// only ever looks at days inside the range, which is what keeps a finished
/// habit from accumulating misses forever after its last day.
final class DateRange extends Equatable {
  /// Throws [ArgumentError] when [end] precedes [start] — an inverted range has
  /// no days in it, so nothing downstream could do anything sensible with it.
  DateRange({required this.start, this.end}) {
    final DateOnly? finish = end;
    if (finish != null && finish < start) {
      throw ArgumentError.value(finish, 'end', 'must not precede $start');
    }
  }

  /// A range that starts on [start] and never ends.
  factory DateRange.openEnded(DateOnly start) => DateRange(start: start);

  /// First day the habit is due, inclusive.
  final DateOnly start;

  /// Last day the habit is due, inclusive; `null` means indefinitely.
  final DateOnly? end;

  /// Whether the habit has no planned end.
  bool get isOpenEnded => end == null;

  /// Whether [date] falls within the range.
  bool contains(DateOnly date) {
    if (date < start) return false;
    final DateOnly? finish = end;
    return finish == null || date <= finish;
  }

  /// The last day of the range that is not in the future relative to [today],
  /// or `null` when the habit has not started yet.
  ///
  /// This is where every backwards walk begins: for a live habit it is today,
  /// and for one that already finished it is its last day.
  DateOnly? lastRelevantDayOn(DateOnly today) {
    if (today < start) return null;
    final DateOnly? finish = end;
    if (finish != null && finish < today) return finish;
    return today;
  }

  /// Returns a copy with the fields given replaced.
  ///
  /// [clearEnd] exists because passing `end: null` cannot be told apart from
  /// omitting it, and turning a bounded habit back into an open-ended one is a
  /// real edit the form has to support.
  DateRange copyWith({DateOnly? start, DateOnly? end, bool clearEnd = false}) =>
      DateRange(
        start: start ?? this.start,
        end: clearEnd ? null : (end ?? this.end),
      );

  @override
  List<Object?> get props => <Object?>[start, end];
}
