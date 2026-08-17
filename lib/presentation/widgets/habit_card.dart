import 'package:flutter/material.dart';

import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_theme.dart';
import '../../config/theme/category_icons.dart';
import '../../config/theme/habit_palette.dart';
import '../../domain/services/habit_completion_policy.dart';
import '../blocs/habits/habits_state.dart';
import '../l10n/domain_labels.dart';
import '../l10n/l10n_extensions.dart';
import '../l10n/schedule_labels.dart';
import 'habit_check_box.dart';

/// One habit on the home screen.
///
/// Draws only what the [HabitSummary] hands it. It never asks whether the check
/// should be enabled or recomputes a streak — those are domain answers already
/// decided in `HabitsBloc`, and a widget with its own opinion would eventually
/// disagree with the write that the repository actually allows.
class HabitCard extends StatelessWidget {
  /// [onToggle] fires only when the check is actually actionable; [onEdit]
  /// fires on a tap anywhere else on the card.
  const HabitCard({
    required this.summary,
    required this.onToggle,
    this.onEdit,
    super.key,
  });

  /// The habit and its derived figures.
  final HabitSummary summary;

  /// Called when the user taps the check.
  final VoidCallback onToggle;

  /// Called when the user taps the card itself, to edit the habit.
  ///
  /// Optional so the card can be rendered read-only — a test, or a future
  /// screen that lists habits without offering to change them.
  final VoidCallback? onEdit;

  /// Width of the colored spine on the leading edge.
  static const double _accentWidth = 5;

  /// Diameter of the icon badge.
  static const double _badgeSize = 56;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color accent = HabitPalette.resolve(context, summary.habit.colorSlot);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppTheme.cardShadow(theme.brightness),
      ),
      // Clipped so the spine takes the card's own rounded corners instead of
      // poking square edges past them.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        // IntrinsicHeight is what makes the spine work at all. `stretch` needs a
        // bounded height to stretch *to*, and inside a ListView the incoming
        // height constraint is infinite — without this the whole card fails to
        // lay out and silently never appears. Cheap here: the card is a shallow
        // row, not a nested tree.
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // The habit's color, carried on the edge rather than as a fill: it
              // has to identify the habit without ever competing with the text.
              SizedBox(width: _accentWidth, child: ColoredBox(color: accent)),
              Expanded(
                // The card body opens the form. The check sits on top with its
                // own gesture, so tapping it never opens the editor by mistake.
                child: InkWell(
                  onTap: onEdit,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: <Widget>[
                        _IconBadge(summary: summary, accent: accent),
                        const SizedBox(width: AppSpacing.gutter),
                        Expanded(child: _Details(summary: summary)),
                        const SizedBox(width: AppSpacing.gutter),
                        HabitCheckBox(
                          accent: accent,
                          isChecked: summary.isCompletedToday,
                          // Tappable when it can be checked *or* unchecked. The
                          // policy blocks re-checking a finished day, but undoing
                          // one is always allowed — a mistap has to be correctable,
                          // and it can only ever shorten a streak, never forge one.
                          isEnabled:
                              summary.isActionable || summary.isCompletedToday,
                          onTap: onToggle,
                          semanticLabel: _checkSemantics(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// What a screen reader says about the check.
  ///
  /// Spelled out rather than left to the default, because "checkbox, disabled"
  /// tells a user nothing about *why* — and the why is the whole rule.
  String _checkSemantics(BuildContext context) {
    final String name = summary.habit.name;
    if (summary.isCompletedToday) {
      return '$name — ${context.l10n.errorCompletionAlreadyRecorded}';
    }
    if (summary.isActionable) return name;
    final CompletionBlockReason? reason = summary.availability.reason;
    return '$name — '
        '${context.l10n.messageForBlockReason(reason, summary.availability)}';
  }
}

/// The rounded badge holding the category glyph.
class _IconBadge extends StatelessWidget {
  /// Creates the badge.
  const _IconBadge({required this.summary, required this.accent});

  /// The habit being drawn.
  final HabitSummary summary;

  /// The habit's resolved color.
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: HabitCard._badgeSize,
      height: HabitCard._badgeSize,
      decoration: BoxDecoration(
        color: HabitPalette.wash(context, summary.habit.colorSlot),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          CategoryIcons.of(summary.habit.category),
          size: 26,
          color: accent,
        ),
      ),
    );
  }
}

/// Name plus the schedule-and-status line under it.
class _Details extends StatelessWidget {
  /// Creates the text block.
  const _Details({required this.summary});

  /// The habit being drawn.
  final HabitSummary summary;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          summary.habit.name,
          style: theme.textTheme.titleLarge?.copyWith(
            // Struck through once today is done — the design's way of saying
            // "handled" without moving the card or changing its color.
            decoration:
                summary.isCompletedToday ? TextDecoration.lineThrough : null,
            decorationColor: scheme.onSurfaceVariant,
            color:
                summary.isCompletedToday
                    ? scheme.onSurfaceVariant
                    : scheme.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        _StatusLine(summary: summary),
      ],
    );
  }
}

/// "Daily · 12 day streak", or "Daily · Not today" when the check is blocked.
///
/// The schedule always shows; what follows it is either the reward or the
/// reason. Keeping them in one line means the card never grows or shrinks as a
/// habit's state changes, which would make the list jump while it is read.
class _StatusLine extends StatelessWidget {
  /// Creates the line.
  const _StatusLine({required this.summary});

  /// The habit being drawn.
  final HabitSummary summary;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextStyle? base = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    // The schedule in force *now*, not the original one: the card describes
    // what the habit asks of the user today.
    final String schedule = context.l10n.labelForSchedule(
      summary.habit.currentSchedule,
    );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      children: <Widget>[
        Text(schedule, style: base),
        Text('·', style: base),
        if (summary.isActionable || summary.isCompletedToday)
          _StreakLabel(streak: summary.streak.current)
        else
          Text(
            context.l10n.messageForBlockReason(
              summary.availability.reason,
              summary.availability,
            ),
            style: base,
          ),
      ],
    );
  }
}

/// The streak count with its flame.
class _StreakLabel extends StatelessWidget {
  /// Creates the label.
  const _StreakLabel({required this.streak});

  /// Current streak in completed days.
  final int streak;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color amber = theme.colorScheme.tertiaryContainer;
    final TextStyle? style = theme.textTheme.bodyMedium?.copyWith(
      color: streak > 0 ? amber : theme.colorScheme.onSurfaceVariant,
      fontWeight: streak > 0 ? FontWeight.w600 : null,
    );

    if (streak == 0) {
      return Text(context.l10n.streakNone, style: style);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(context.l10n.streakDays(streak), style: style),
        const SizedBox(width: AppSpacing.xs),
        // An icon rather than the 🔥 emoji: emoji render differently on every
        // platform and cannot take the theme's color.
        Icon(Icons.local_fire_department_rounded, size: 16, color: amber),
      ],
    );
  }
}
