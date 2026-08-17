import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../config/theme/app_dimens.dart';
import '../../../domain/repositories/entries_repository.dart';
import '../../../domain/repositories/habits_repository.dart';
import '../../blocs/habits/habits_bloc.dart';
import '../../blocs/habits/habits_event.dart';
import '../../blocs/habits/habits_state.dart';
import '../../l10n/failure_messages.dart';
import '../../l10n/l10n_extensions.dart';
import '../../widgets/habit_card.dart';
import 'debug_seed_button.dart';

/// The main panel: the day's greeting and the habit list.
///
/// Owns its own `HabitsBloc` rather than taking one from above, per
/// `ARCHITECTURE.md` §7 — blocs are per context, and the list's subscription
/// should end when the screen does. The repositories come from the providers
/// mounted at the root.
class HomeScreen extends StatelessWidget {
  /// Creates the main panel.
  const HomeScreen({super.key});

  /// Route path this screen is registered under.
  static const String routePath = '/';

  /// Route name used for navigation by name.
  static const String routeName = 'home';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HabitsBloc>(
      create:
          (BuildContext context) => HabitsBloc(
            habitsRepository: context.read<HabitsRepository>(),
            entriesRepository: context.read<EntriesRepository>(),
          )..add(const HabitsSubscriptionRequested()),
      child: const _HomeView(),
    );
  }
}

/// The rendered screen, split from the provider so it can read the bloc.
class _HomeView extends StatelessWidget {
  /// Creates the view.
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.appTitle)),
      // Debug only, and gone from release builds. Phase 4 replaces it with the
      // real "new habit" entry point.
      floatingActionButton: DebugSeedButton.maybeBuild(
        habits: context.read<HabitsRepository>(),
        entries: context.read<EntriesRepository>(),
        onSeeded: () {},
      ),
      body: BlocConsumer<HabitsBloc, HabitsState>(
        // Refusals are transient and belong in a snackbar, not in the layout:
        // the list itself is fine, one tap was not.
        listenWhen:
            (HabitsState previous, HabitsState current) =>
                current.actionFailure != null &&
                current.actionSeq != previous.actionSeq,
        listener: (BuildContext context, HabitsState state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  context.l10n.messageForFailure(state.actionFailure!),
                ),
              ),
            );
        },
        builder: (BuildContext context, HabitsState state) {
          return switch (state.status) {
            HabitsStatus.initial || HabitsStatus.loading => const _Centered(
              child: CircularProgressIndicator(),
            ),
            HabitsStatus.failure => _LoadFailure(state: state),
            HabitsStatus.ready => _Loaded(state: state),
          };
        },
      ),
    );
  }
}

/// The list and its header.
class _Loaded extends StatelessWidget {
  /// Creates the loaded body.
  const _Loaded({required this.state});

  /// The state being rendered.
  final HabitsState state;

  @override
  Widget build(BuildContext context) {
    final HabitsBloc bloc = context.read<HabitsBloc>();

    return ListView(
      padding: const EdgeInsets.only(
        left: AppSpacing.screenMargin,
        right: AppSpacing.screenMargin,
        top: AppSpacing.sm,
        // Clear of the floating button *and* the navigation bar. Measured, not
        // guessed: the extended FAB is 56 tall with 16 of margin, and the last
        // card was being covered by it.
        bottom: AppSpacing.xl * 3,
      ),
      children: <Widget>[
        _Header(state: state),
        const SizedBox(height: AppSpacing.lg),
        if (state.isEmpty)
          const _EmptyState()
        else
          for (final HabitSummary summary in state.summaries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: HabitCard(
                summary: summary,
                onToggle: () => bloc.add(HabitCheckToggled(summary.habit)),
              ),
            ),
      ],
    );
  }
}

/// Date, greeting and the day's summary.
class _Header extends StatelessWidget {
  /// Creates the header.
  const _Header({required this.state});

  /// The state being rendered.
  final HabitsState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    // Formatted through intl with the active locale, not through the .arb
    // files: date patterns per language are already in the ICU data.
    final String date = DateFormat.yMMMMEEEEd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(state.today.toDateTime());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          date,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(_greeting(context), style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _summary(context),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Time-of-day greeting, with no name attached.
  ///
  /// The design shows "Good morning, Alex." but the account is anonymous until
  /// the final phase, so there is no name to use — and a greeting with a blank
  /// where the name goes is worse than one without.
  String _greeting(BuildContext context) {
    final int hour = DateTime.now().hour;
    if (hour < 12) return context.l10n.homeGreetingMorning;
    if (hour < 19) return context.l10n.homeGreetingAfternoon;
    return context.l10n.homeGreetingEvening;
  }

  /// "You have 3 habits left to complete today", or the honest alternatives.
  String _summary(BuildContext context) {
    if (state.isEmpty) return context.l10n.homeEmpty;
    // Nothing due is not the same as nothing left: congratulating someone for a
    // day their habits never fell on would be congratulating the calendar.
    if (!state.anythingDueToday) return context.l10n.homeNothingDueToday;
    return context.l10n.homeHabitsLeft(state.pendingToday);
  }
}

/// Shown when the user has no habits yet.
class _EmptyState extends StatelessWidget {
  /// Creates the empty state.
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.flag_outlined,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.homeEmptyHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when the subscription failed before delivering anything.
class _LoadFailure extends StatelessWidget {
  /// Creates the failure body.
  const _LoadFailure({required this.state});

  /// The state being rendered.
  final HabitsState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String message =
        state.loadFailure == null
            ? context.l10n.errorUnknown
            : context.l10n.messageForFailure(state.loadFailure!);

    return _Centered(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenMargin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

/// Centres a child. Saves repeating the same two wrappers.
class _Centered extends StatelessWidget {
  /// Creates the wrapper.
  const _Centered({required this.child});

  /// What to centre.
  final Widget child;

  @override
  Widget build(BuildContext context) => Center(child: child);
}
