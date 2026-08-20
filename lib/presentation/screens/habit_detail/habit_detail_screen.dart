import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../config/theme/app_dimens.dart';
import '../../../config/theme/app_theme.dart';
import '../../../config/theme/category_icons.dart';
import '../../../config/theme/habit_palette.dart';
import '../../../domain/entities/date_only.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/repositories/entries_repository.dart';
import '../../../domain/repositories/habits_repository.dart';
import '../../../domain/services/habit_day_status.dart';
import '../../blocs/habit_detail/habit_detail_cubit.dart';
import '../../blocs/habit_detail/habit_detail_state.dart';
import '../../l10n/failure_messages.dart';
import '../../l10n/l10n_extensions.dart';
import '../../l10n/schedule_labels.dart';
import '../habit_form/habit_form_screen.dart';
import '../../widgets/contribution_grid.dart';
import '../../widgets/month_calendar.dart';

/// Everything about one habit: its history as a grid, its streak, and a month
/// calendar underneath.
///
/// Reached by tapping a habit card. Until now that opened the form directly,
/// which meant there was no way to *look* at a habit without being put in a
/// position to change it. Editing moved to an action in here.
class HabitDetailScreen extends StatelessWidget {
  /// [habitId] comes from the route.
  const HabitDetailScreen({required this.habitId, super.key});

  /// Which habit to show.
  final String habitId;

  /// Route path, with the habit id as a parameter.
  static const String routePath = '/habit/:habitId';

  /// The concrete path for [id].
  static String pathFor(String id) => '/habit/$id';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HabitDetailCubit>(
      create:
          (BuildContext context) => HabitDetailCubit(
            habitsRepository: context.read<HabitsRepository>(),
            entriesRepository: context.read<EntriesRepository>(),
            habitId: habitId,
          )..load(),
      child: const _DetailView(),
    );
  }
}

/// The rendered screen.
class _DetailView extends StatelessWidget {
  /// Creates the view.
  const _DetailView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HabitDetailCubit, HabitDetailState>(
      builder: (BuildContext context, HabitDetailState state) {
        final Habit? habit = state.habit;

        return Scaffold(
          appBar: AppBar(
            // An X rather than a back arrow: this is a panel you dismiss, not a
            // place you navigated into.
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: context.l10n.detailClose,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: Text(habit?.name ?? context.l10n.detailTitle),
            titleTextStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            centerTitle: false,
            actions: <Widget>[
              if (habit != null)
                TextButton(
                  onPressed:
                      () => context.push(HabitFormScreen.editPathFor(habit.id)),
                  child: Text(context.l10n.detailEdit),
                ),
            ],
          ),
          body: switch (state.status) {
            HabitDetailStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            HabitDetailStatus.failure => _Failure(state: state),
            HabitDetailStatus.ready => _Loaded(state: state, habit: habit!),
          },
        );
      },
    );
  }
}

/// The two panels.
class _Loaded extends StatelessWidget {
  /// Creates the body.
  const _Loaded({required this.state, required this.habit});

  /// What to draw.
  final HabitDetailState state;

  /// The habit, already known to be loaded.
  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final Color accent = HabitPalette.resolve(context, habit.colorSlot);

    // Filtered once and closed over by both grids. Each of them asks about
    // hundreds of days, and re-filtering the whole history per cell would be
    // the easiest possible way to make this screen slow.
    final Set<DateOnly> completed = HabitDayStatuses.completedDaysOf(
      habit,
      state.entries,
    );
    DayStatus statusOf(DateOnly date) => HabitDayStatuses.on(
      habit: habit,
      completedDays: completed,
      date: date,
      today: state.today,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.sm,
        AppSpacing.screenMargin,
        AppSpacing.xl,
      ),
      children: <Widget>[
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Heading(habit: habit, accent: accent),
              const SizedBox(height: AppSpacing.lg),
              ContributionGrid(
                today: state.today,
                statusOf: statusOf,
                accent: accent,
              ),
              const SizedBox(height: AppSpacing.md),
              Divider(color: Theme.of(context).colorScheme.outlineVariant),
              const SizedBox(height: AppSpacing.md),
              _Chips(state: state, habit: habit),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Panel(
          child: Column(
            children: <Widget>[
              _MonthHeader(state: state),
              const SizedBox(height: AppSpacing.md),
              MonthCalendar(
                month: state.visibleMonth,
                today: state.today,
                statusOf: statusOf,
                accent: accent,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A white card on the tinted plane, like everything else in this app.
class _Panel extends StatelessWidget {
  /// Creates the panel.
  const _Panel({required this.child});

  /// Its contents.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppTheme.cardShadow(theme.brightness),
      ),
      child: child,
    );
  }
}

/// Icon badge and name.
class _Heading extends StatelessWidget {
  /// Creates the heading.
  const _Heading({required this.habit, required this.accent});

  /// The habit.
  final Habit habit;

  /// Its color.
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: HabitPalette.wash(context, habit.colorSlot),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Center(
            child: Icon(
              CategoryIcons.of(habit.category),
              size: 24,
              color: accent,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.gutter),
        Expanded(child: Text(habit.name, style: theme.textTheme.titleLarge)),
      ],
    );
  }
}

/// Schedule, current streak and best streak.
class _Chips extends StatelessWidget {
  /// Creates the chip row.
  const _Chips({required this.state, required this.habit});

  /// What to draw.
  final HabitDetailState state;

  /// The habit.
  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        _Chip(label: context.l10n.labelForSchedule(habit.currentSchedule)),
        _Chip(
          label: context.l10n.detailStreakChip(state.streak.current),
          icon: Icons.local_fire_department_rounded,
          iconColor: theme.colorScheme.tertiaryContainer,
        ),
        // The true best, not the home screen's. That one is capped by the
        // 400-day window the list loads; this cubit reads the whole history.
        _Chip(label: context.l10n.detailLongestStreak(state.streak.longest)),
      ],
    );
  }
}

/// One pill.
class _Chip extends StatelessWidget {
  /// Creates the chip.
  const _Chip({required this.label, this.icon, this.iconColor});

  /// Already-localized text.
  final String label;

  /// Optional leading glyph.
  final IconData? icon;

  /// Its color.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Aug 2026" with the two arrows.
class _MonthHeader extends StatelessWidget {
  /// Creates the header.
  const _MonthHeader({required this.state});

  /// What to draw.
  final HabitDetailState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HabitDetailCubit cubit = context.read<HabitDetailCubit>();
    final String label = DateFormat.yMMMM(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(state.visibleMonth.toDateTime());

    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _capitalize(label),
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
              ),
            ],
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: cubit.previousMonth,
          tooltip: context.l10n.detailPreviousMonth,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        IconButton(
          // Disabled at the current month: there is nothing to see in the
          // future, and paging into next year one tap at a time is not
          // navigation.
          onPressed: state.canGoForward ? cubit.nextMonth : null,
          tooltip: context.l10n.detailNextMonth,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }

  /// Upper-cases the first letter; Spanish month names arrive lower-cased.
  String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}

/// Shown when the habit could not be read.
class _Failure extends StatelessWidget {
  /// Creates the failure body.
  const _Failure({required this.state});

  /// Carries the reason.
  final HabitDetailState state;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenMargin),
        child: Text(
          state.failure == null
              ? context.l10n.errorUnknown
              : context.l10n.messageForFailure(state.failure!),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
