import 'package:equatable/equatable.dart';

import 'date_only.dart';

/// The streak figures for one habit, always derived and never stored.
///
/// A counter kept in the database desynchronizes the first time an old entry is
/// edited or a schedule changes; recomputing from the entries cannot
/// (`ARCHITECTURE.md` §4). This type is therefore a result, not a record — it
/// has no id and nothing writes it.
final class Streak extends Equatable {
  /// [current] and [longest] are counts of *completed days*, not of periods.
  const Streak({
    required this.current,
    required this.longest,
    this.lastCompletedDate,
  });

  /// The zero value, for a habit with no entries at all.
  static const Streak empty = Streak(current: 0, longest: 0);

  /// Days in the run that is still alive today.
  ///
  /// Zero once a scheduled day is missed. Today never counts against it: the
  /// day is open until midnight, so an unchecked habit is pending, not failed.
  final int current;

  /// The best run ever achieved, including the current one.
  final int longest;

  /// The most recent day with an entry, or `null` if there are none.
  final DateOnly? lastCompletedDate;

  /// Whether the habit has ever been completed.
  bool get hasHistory => lastCompletedDate != null;

  @override
  List<Object?> get props => <Object?>[current, longest, lastCompletedDate];

  @override
  String toString() =>
      'Streak(current: $current, longest: $longest, '
      'lastCompletedDate: $lastCompletedDate)';
}
