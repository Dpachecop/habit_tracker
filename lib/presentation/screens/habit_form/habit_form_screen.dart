import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../config/theme/app_dimens.dart';
import '../../../domain/entities/date_only.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/entities/habit_category.dart';
import '../../../domain/entities/habit_color_slot.dart';
import '../../../domain/entities/time_window.dart';
import '../../../domain/repositories/entries_repository.dart';
import '../../../domain/repositories/habits_repository.dart';
import '../../../domain/services/schedule_change_policy.dart';
import '../../blocs/habit_form/habit_form_cubit.dart';
import '../../blocs/habit_form/habit_form_state.dart';
import '../../l10n/domain_labels.dart';
import '../../l10n/failure_messages.dart';
import '../../l10n/form_messages.dart';
import '../../l10n/l10n_extensions.dart';
import 'widgets/color_picker_row.dart';
import 'widgets/form_section.dart';
import 'widgets/schedule_fields.dart';

/// Create or edit a habit.
///
/// One screen for both, because they differ in three places — the title, the
/// "from when does this apply" notice, and the archive action — and two screens
/// would duplicate every field to avoid duplicating those three.
class HabitFormScreen extends StatelessWidget {
  /// [habit] null means create.
  const HabitFormScreen({this.habit, this.suggestedColor, super.key});

  /// The habit being edited, or null when creating one.
  final Habit? habit;

  /// Which palette slot a new habit should start on.
  ///
  /// Supplied by whoever opened the form, because they know which slots are
  /// already taken. Ignored when editing.
  final HabitColorSlot? suggestedColor;

  /// Route path for creating.
  static const String createPath = '/habit/new';

  /// The concrete edit path for [id].
  ///
  /// A sub-route of the detail screen rather than a root one: `/habit/:id` is
  /// the habit, and editing it is something you do *to* it.
  static String editPathFor(String id) => '/habit/$id/edit';

  @override
  Widget build(BuildContext context) {
    final Habit? editing = habit;

    return BlocProvider<HabitFormCubit>(
      create: (BuildContext context) {
        final HabitsRepository habits = context.read<HabitsRepository>();
        final EntriesRepository entries = context.read<EntriesRepository>();
        return editing == null
            ? HabitFormCubit.create(
              habitsRepository: habits,
              entriesRepository: entries,
              suggestedColor: suggestedColor ?? HabitColorSlot.blue,
            )
            : HabitFormCubit.edit(
              habitsRepository: habits,
              entriesRepository: entries,
              habit: editing,
            );
      },
      child: const _FormView(),
    );
  }
}

/// The rendered form, split out so it can read the cubit.
class _FormView extends StatelessWidget {
  /// Creates the view.
  const _FormView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HabitFormCubit, HabitFormState>(
      listenWhen:
          (HabitFormState previous, HabitFormState current) =>
              previous.status != current.status ||
              previous.pendingWarning != current.pendingWarning,
      listener: _onStateChanged,
      builder:
          (BuildContext context, HabitFormState state) =>
              _FormScaffold(state: state),
    );
  }

  /// Closes on success, explains on failure, asks on the §3.4 warning.
  void _onStateChanged(BuildContext context, HabitFormState state) {
    final PeriodReachability? warning = state.pendingWarning;
    if (warning != null) {
      _showUnreachableDialog(context, warning);
      return;
    }

    switch (state.status) {
      case HabitFormStatus.saved:
      case HabitFormStatus.archived:
        final String message = switch (state.status) {
          HabitFormStatus.archived => context.l10n.formArchived,
          _ when state.isEditing => context.l10n.formSavedEdit,
          _ => context.l10n.formSavedCreate,
        };
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
        Navigator.of(context).pop();
      case HabitFormStatus.failure:
        final String message =
            state.failure == null
                ? context.l10n.errorUnknown
                : context.l10n.messageForFailure(state.failure!);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      case HabitFormStatus.editing:
      case HabitFormStatus.saving:
        break;
    }
  }

  /// The warning §3.4 demands, as a decision rather than a notification.
  ///
  /// Two real options, and neither is preselected as safe: the change may well
  /// be what the user wants, they just have to know it costs the streak.
  Future<void> _showUnreachableDialog(
    BuildContext context,
    PeriodReachability warning,
  ) async {
    final HabitFormCubit cubit = context.read<HabitFormCubit>();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            title: Text(dialogContext.l10n.formUnreachableTitle),
            content: Text(
              dialogContext.l10n.messageForUnreachablePeriod(warning),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(dialogContext.l10n.formBack),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(dialogContext.l10n.formUnreachableConfirm),
              ),
            ],
          ),
    );

    if (confirmed ?? false) {
      await cubit.confirmSave();
    } else {
      cubit.warningDismissed();
    }
  }
}

/// Chrome plus the scrolling body.
class _FormScaffold extends StatelessWidget {
  /// Creates the scaffold.
  const _FormScaffold({required this.state});

  /// The form state being rendered.
  final HabitFormState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final HabitFormCubit cubit = context.read<HabitFormCubit>();
    final bool isBusy = state.status == HabitFormStatus.saving;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.isEditing
              ? context.l10n.formTitleEdit
              : context.l10n.formTitleCreate,
        ),
        titleTextStyle: theme.textTheme.headlineMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMargin,
          AppSpacing.md,
          AppSpacing.screenMargin,
          AppSpacing.xl * 3,
        ),
        children: <Widget>[
          _NameField(state: state),
          FormSection(
            title: context.l10n.formColorLabel,
            child: ColorPickerRow(
              selected: state.colorSlot,
              onChanged: cubit.colorChanged,
            ),
          ),
          _CategorySection(state: state),
          FormSection(
            title: context.l10n.formScheduleLabel,
            error:
                _errorFor(context, HabitFormField.weekdays) ??
                _errorFor(context, HabitFormField.times),
            child: ScheduleFields(state: state),
          ),
          if (state.isEditing && state.hasScheduleChanged)
            _ScheduleChangeNotice(state: state),
          _TimeWindowSection(state: state),
          _DatesSection(state: state),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isBusy ? null : cubit.submit,
              child:
                  isBusy
                      ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text(context.l10n.formSave),
            ),
          ),
          if (state.isEditing) _ArchiveSection(isBusy: isBusy),
        ],
      ),
    );
  }

  /// The message for [field], or null when it is fine or not yet shown.
  String? _errorFor(BuildContext context, HabitFormField field) {
    if (!state.showErrors || !state.invalidFields.contains(field)) return null;
    return context.l10n.messageForFormField(field, maxTimes: state.maxTimes);
  }
}

/// The name input.
class _NameField extends StatefulWidget {
  /// Creates the field.
  const _NameField({required this.state});

  /// The form state being rendered.
  final HabitFormState state;

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  /// Held in state rather than rebuilt from the cubit each frame, so the caret
  /// does not jump to the end while the user types in the middle of a word.
  late final TextEditingController _controller = TextEditingController(
    text: widget.state.name,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final HabitFormState state = widget.state;
    final bool hasError =
        state.showErrors && state.invalidFields.contains(HabitFormField.name);

    return FormSection(
      title: context.l10n.formNameLabel,
      error: hasError ? context.l10n.formNameRequired : null,
      child: TextField(
        controller: _controller,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          hintText: context.l10n.formNameHint,
          border: const UnderlineInputBorder(),
        ),
        onChanged: context.read<HabitFormCubit>().nameChanged,
      ),
    );
  }
}

/// The category chips.
class _CategorySection extends StatelessWidget {
  /// Creates the section.
  const _CategorySection({required this.state});

  /// The form state being rendered.
  final HabitFormState state;

  @override
  Widget build(BuildContext context) {
    final HabitFormCubit cubit = context.read<HabitFormCubit>();
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return FormSection(
      title: context.l10n.formCategoryLabel,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: <Widget>[
          for (final HabitCategory category in HabitCategory.values)
            ChoiceChip(
              label: Text(context.l10n.labelForCategory(category)),
              selected: state.category == category,
              showCheckmark: false,
              selectedColor: scheme.primary,
              labelStyle: TextStyle(
                color:
                    state.category == category
                        ? scheme.onPrimary
                        : scheme.onSurfaceVariant,
              ),
              onSelected: (_) => cubit.categoryChanged(category),
            ),
        ],
      ),
    );
  }
}

/// The §3.4 "from when does this apply" notice.
///
/// Only while editing, and only when the schedule actually changed. It is
/// reassurance as much as information: the commonest fear when editing a habit
/// is losing the streak, and the answer is that you cannot.
class _ScheduleChangeNotice extends StatelessWidget {
  /// Creates the notice.
  const _ScheduleChangeNotice({required this.state});

  /// The form state being rendered.
  final HabitFormState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline_rounded, size: 20, color: scheme.secondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.noticeForScheduleChange(state.schedule),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// All-day switch plus the two time pickers.
class _TimeWindowSection extends StatelessWidget {
  /// Creates the section.
  const _TimeWindowSection({required this.state});

  /// The form state being rendered.
  final HabitFormState state;

  @override
  Widget build(BuildContext context) {
    final HabitFormCubit cubit = context.read<HabitFormCubit>();
    final TimeWindow? window = state.timeWindow;

    return FormSection(
      title: context.l10n.formTimeWindowLabel,
      error:
          state.showErrors &&
                  state.invalidFields.contains(HabitFormField.timeWindow)
              ? context.l10n.formTimeWindowInvalid
              : null,
      child: Column(
        children: <Widget>[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.l10n.formAllDay),
            value: window == null,
            onChanged: (bool value) => cubit.allDayToggled(isAllDay: value),
          ),
          if (window != null)
            Row(
              children: <Widget>[
                Expanded(
                  child: _TimeField(
                    label: context.l10n.formTimeFrom,
                    minuteOfDay: window.startMinuteOfDay,
                    onChanged:
                        (int minute) => cubit.timeWindowChanged(
                          TimeWindow(
                            startMinuteOfDay: minute,
                            // Kept ahead of the start so the picker can never build
                            // an inverted window that the entity would reject.
                            endMinuteOfDay:
                                window.endMinuteOfDay > minute
                                    ? window.endMinuteOfDay
                                    : minute + 60,
                          ),
                        ),
                  ),
                ),
                const SizedBox(width: AppSpacing.gutter),
                Expanded(
                  child: _TimeField(
                    label: context.l10n.formTimeTo,
                    minuteOfDay: window.endMinuteOfDay,
                    onChanged:
                        (int minute) => cubit.timeWindowChanged(
                          TimeWindow(
                            startMinuteOfDay:
                                window.startMinuteOfDay < minute
                                    ? window.startMinuteOfDay
                                    : (minute - 60).clamp(0, 1439),
                            endMinuteOfDay: minute,
                          ),
                        ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// A labelled button that opens the platform time picker.
class _TimeField extends StatelessWidget {
  /// Creates the field.
  const _TimeField({
    required this.label,
    required this.minuteOfDay,
    required this.onChanged,
  });

  /// Already-localized caption.
  final String label;

  /// Current value, in minutes past midnight.
  final int minuteOfDay;

  /// Called with the new value.
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TimeOfDay value = TimeOfDay(
      hour: minuteOfDay ~/ 60,
      minute: minuteOfDay % 60,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        OutlinedButton(
          onPressed: () async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: value,
            );
            if (picked != null) onChanged(picked.hour * 60 + picked.minute);
          },
          child: Text(value.format(context)),
        ),
      ],
    );
  }
}

/// Start date, end date, and the open-ended switch.
class _DatesSection extends StatelessWidget {
  /// Creates the section.
  const _DatesSection({required this.state});

  /// The form state being rendered.
  final HabitFormState state;

  @override
  Widget build(BuildContext context) {
    final HabitFormCubit cubit = context.read<HabitFormCubit>();
    final DateOnly? end = state.rangeEnd;

    return FormSection(
      title: context.l10n.formDatesLabel,
      error:
          state.showErrors &&
                  state.invalidFields.contains(HabitFormField.dateRange)
              ? context.l10n.formEndBeforeStart
              : null,
      child: Column(
        children: <Widget>[
          _DateField(
            label: context.l10n.formStartDate,
            value: state.rangeStart,
            onChanged: cubit.startDateChanged,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.l10n.formNoEndDate),
            value: end == null,
            onChanged:
                (bool value) =>
                    value
                        ? cubit.endDateCleared()
                        : cubit.endDateChanged(state.rangeStart.addDays(30)),
          ),
          if (end != null)
            _DateField(
              label: context.l10n.formEndDate,
              value: end,
              onChanged: cubit.endDateChanged,
            ),
        ],
      ),
    );
  }
}

/// A labelled button that opens the platform date picker.
class _DateField extends StatelessWidget {
  /// Creates the field.
  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  /// Already-localized caption.
  final String label;

  /// Current value.
  final DateOnly value;

  /// Called with the new value.
  final ValueChanged<DateOnly> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String formatted = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(value.toDateTime());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Text(label, style: theme.textTheme.bodyLarge),
          const Spacer(),
          OutlinedButton(
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: value.toDateTime(),
                // Ten years either way: enough for a habit that started a while
                // ago or one planned well ahead, without an infinite scroll.
                firstDate: DateTime(value.year - 10),
                lastDate: DateTime(value.year + 10, 12, 31),
              );
              if (picked != null) onChanged(DateOnly.fromDateTime(picked));
            },
            child: Text(formatted),
          ),
        ],
      ),
    );
  }
}

/// The archive action, and the sentence that stops it reading as a delete.
class _ArchiveSection extends StatelessWidget {
  /// Creates the section.
  const _ArchiveSection({required this.isBusy});

  /// Whether a write is already in flight.
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        children: <Widget>[
          OutlinedButton.icon(
            onPressed: isBusy ? null : () => _confirm(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.error,
              side: BorderSide(color: scheme.error),
            ),
            icon: const Icon(Icons.archive_outlined),
            label: Text(context.l10n.formArchive),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            // Said out loud because "archive" next to a red border reads as
            // "delete", and the whole point is that nothing is destroyed.
            context.l10n.formArchiveExplain,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Asks before archiving.
  Future<void> _confirm(BuildContext context) async {
    final HabitFormCubit cubit = context.read<HabitFormCubit>();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            title: Text(dialogContext.l10n.formArchiveConfirmTitle),
            content: Text(dialogContext.l10n.formArchiveExplain),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(dialogContext.l10n.formBack),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(dialogContext.l10n.formArchiveConfirm),
              ),
            ],
          ),
    );

    if (confirmed ?? false) await cubit.archive();
  }
}
