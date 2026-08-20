import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// `hide State`: fpdart exports a State monad that collides with Flutter's
// StatefulWidget State, and this file needs the Flutter one.
import 'package:fpdart/fpdart.dart' hide State;

import '../../../config/theme/app_dimens.dart';
import '../../../domain/entities/habit.dart';
import '../../../domain/failures/failure.dart';
import '../../../domain/repositories/habits_repository.dart';
import '../../l10n/failure_messages.dart';
import '../../l10n/l10n_extensions.dart';
import 'habit_form_screen.dart';

/// Fetches the habit an edit route names, then shows the form.
///
/// The route could have carried the whole entity in `extra` — the only way in
/// is tapping a card, which already has one — but then a deep link or a restored
/// route would arrive with nothing and crash. Fetching by id is one code path
/// that always works, and with Firestore's offline cache it resolves from local
/// storage, so the spinner is rarely seen.
class HabitFormLoader extends StatefulWidget {
  /// [habitId] comes from the route.
  const HabitFormLoader({required this.habitId, super.key});

  /// Which habit to edit.
  final String habitId;

  @override
  State<HabitFormLoader> createState() => _HabitFormLoaderState();
}

class _HabitFormLoaderState extends State<HabitFormLoader> {
  /// Started once in initState rather than in build, or every rebuild would
  /// fire another read.
  late final Future<Either<Failure, Habit>> _habit = context
      .read<HabitsRepository>()
      .getHabit(widget.habitId);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Either<Failure, Habit>>(
      future: _habit,
      builder: (
        BuildContext context,
        AsyncSnapshot<Either<Failure, Habit>> snapshot,
      ) {
        final Either<Failure, Habit>? result = snapshot.data;
        if (result == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return result.match(
          (Failure failure) => _LoadFailure(failure: failure),
          (Habit habit) => HabitFormScreen(habit: habit),
        );
      },
    );
  }
}

/// Shown when the habit could not be read.
class _LoadFailure extends StatelessWidget {
  /// Creates the failure screen.
  const _LoadFailure({required this.failure});

  /// Why the read failed.
  final Failure failure;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenMargin),
          child: Text(
            context.l10n.messageForFailure(failure),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
