import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../config/theme/app_dimens.dart';
import '../../../../domain/entities/habit_schedule.dart';
import '../../../../domain/entities/weekday.dart';
import '../../../blocs/habit_form/habit_form_cubit.dart';
import '../../../blocs/habit_form/habit_form_state.dart';
import '../../../l10n/form_messages.dart';
import '../../../l10n/l10n_extensions.dart';

/// The schedule half of the form: pick a mode, then fill that mode in.
///
/// The two modes are presented as a real choice rather than a single "frequency"
/// control, because they are different commitments. "Mon, Wed, Fri" says *which*
/// days and the app will refuse a Tuesday; "3 a week" leaves the days to the
/// user. Collapsing them into one widget would hide that.
class ScheduleFields extends StatelessWidget {
  /// Creates the schedule fields.
  const ScheduleFields({required this.state, super.key});

  /// The form state being edited.
  final HabitFormState state;

  @override
  Widget build(BuildContext context) {
    final HabitFormCubit cubit = context.read<HabitFormCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SegmentedButton<ScheduleMode>(
          segments: <ButtonSegment<ScheduleMode>>[
            ButtonSegment<ScheduleMode>(
              value: ScheduleMode.weekdays,
              label: Text(context.l10n.formScheduleModeWeekdays),
            ),
            ButtonSegment<ScheduleMode>(
              value: ScheduleMode.timesPerPeriod,
              label: Text(context.l10n.formScheduleModeTimes),
            ),
          ],
          selected: <ScheduleMode>{state.scheduleMode},
          showSelectedIcon: false,
          onSelectionChanged:
              (Set<ScheduleMode> selection) =>
                  cubit.scheduleModeChanged(selection.first),
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.scheduleMode == ScheduleMode.weekdays)
          _WeekdayPicker(state: state)
        else
          _TimesPerPeriodPicker(state: state),
      ],
    );
  }
}

/// Seven toggles plus an "every day" shortcut.
class _WeekdayPicker extends StatelessWidget {
  /// Creates the picker.
  const _WeekdayPicker({required this.state});

  /// The form state being edited.
  final HabitFormState state;

  @override
  Widget build(BuildContext context) {
    final HabitFormCubit cubit = context.read<HabitFormCubit>();
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    // Day names from ICU rather than the .arb files — every locale's
    // abbreviations are already there.
    final DateFormat format = DateFormat.E(
      Localizations.localeOf(context).toLanguageTag(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final Weekday day in Weekday.values)
              FilterChip(
                // 2026-08-03 is a Monday, so the ISO number indexes that week.
                label: Text(format.format(DateTime(2026, 8, 2 + day.isoValue))),
                selected: state.weekdays.contains(day),
                showCheckmark: false,
                selectedColor: scheme.primary,
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  color:
                      state.weekdays.contains(day)
                          ? scheme.onPrimary
                          : scheme.onSurfaceVariant,
                ),
                onSelected: (_) => cubit.weekdayToggled(day),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: cubit.everyDaySelected,
          child: Text(context.l10n.formEveryDay),
        ),
      ],
    );
  }
}

/// A stepper for the count and a selector for the bucket.
class _TimesPerPeriodPicker extends StatelessWidget {
  /// Creates the picker.
  const _TimesPerPeriodPicker({required this.state});

  /// The form state being edited.
  final HabitFormState state;

  @override
  Widget build(BuildContext context) {
    final HabitFormCubit cubit = context.read<HabitFormCubit>();
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(context.l10n.formTimesLabel, style: theme.textTheme.bodyLarge),
            const Spacer(),
            IconButton.outlined(
              // Disabled at the ends rather than clamping silently, so the
              // ceiling is visible instead of mysterious.
              onPressed:
                  state.times > 1
                      ? () => cubit.timesChanged(state.times - 1)
                      : null,
              icon: const Icon(Icons.remove_rounded),
            ),
            SizedBox(
              width: 56,
              child: Text(
                '${state.times}',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
            ),
            IconButton.outlined(
              onPressed:
                  state.times < state.maxTimes
                      ? () => cubit.timesChanged(state.times + 1)
                      : null,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(context.l10n.formPeriodLabel, style: theme.textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<SchedulePeriod>(
          segments: <ButtonSegment<SchedulePeriod>>[
            for (final SchedulePeriod period in SchedulePeriod.values)
              ButtonSegment<SchedulePeriod>(
                value: period,
                label: Text(context.l10n.labelForPeriod(period)),
              ),
          ],
          selected: <SchedulePeriod>{state.period},
          showSelectedIcon: false,
          onSelectionChanged:
              (Set<SchedulePeriod> selection) =>
                  cubit.periodChanged(selection.first),
        ),
      ],
    );
  }
}
