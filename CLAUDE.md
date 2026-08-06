# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`habit_tracker` — a personal habit/goal tracker. The user creates goals ("metas") with a name,
color, category, schedule and optional date range, checks them off daily, and reviews streaks,
a year heatmap, and per-goal consistency charts.

**Read `docs/ARCHITECTURE.md` before writing any code.** It holds the domain model, the streak
rules, the layer boundaries and the phased roadmap. It is the source of truth for design
decisions; this file only covers conventions and commands.

**Read `docs/STATUS.md` to find out where the build currently is** — current phase, what exists,
what is decided, what is next. Update it as part of the PR that closes each phase; a stale status
file is worse than none.

Flutter stable 3.29.3, Dart `^3.7.2`. Platforms: **android + ios** (`web/` exists but is out of
scope). Bundle id is still the default `com.example.habit_tracker`.

## Architecture

Three layers, dependencies point inward — `presentation → domain ← infrastructure`:

- `lib/domain/` — pure Dart. **No Flutter, Firebase or I/O imports, ever.** Entities, the
  `StreakCalculator` domain service, abstract repository/datasource contracts, sealed `Failure`s.
- `lib/infrastructure/` — implements the domain contracts. Firestore datasources, DTOs, mappers,
  exception→`Failure` translation. Swappable by design.
- `lib/presentation/` — blocs, screens, widgets. Talks to the domain contracts, never to Firestore.
- `lib/config/` — DI composition root, router, theme, constants.

Key invariants:

- `HabitSchedule` is a **sealed** union: `SpecificWeekdays` | `TimesPerPeriod`. Daily is
  `SpecificWeekdays` with all 7 days — do not add a third case for it.
- **A habit has no single `schedule` field.** It holds an ordered `List<ScheduleVersion>`; always
  read it through `habit.scheduleOn(date)`. Editing a schedule appends a version, never
  overwrites — a streak earned under the old rules must survive the change.
- **Over-completion is not allowed** (`ARCHITECTURE.md` §3.5). Only scheduled days can be checked
  in `SpecificWeekdays`; `TimesPerPeriod` caps at `times` per period. The domain enforces this and
  returns `ValidationFailure`; the UI only disables the button as a courtesy.
- **Streaks are always derived, never persisted.** A stored counter desyncs the moment an old
  entry is edited or a schedule changes.
- All streak math uses **local dates normalized to midnight**; `completedAt` is stored in UTC.
  Week starts Monday (ISO 8601).
- Today never breaks a streak, and neither does the current open period — both are still in play.
- Entry document id is `{habitId}_{yyyy-MM-dd}` — gives uniqueness and idempotent toggles.
- Habits are archived, never hard-deleted; deleting would destroy history.
- Repositories return `Either<Failure, T>`. `Failure`s carry a stable `code`, never user-facing
  text — presentation maps code → string.

## Conventions

- **Every class and every function gets a dartdoc `///` comment, in English.** Explain the *why*;
  do not restate the signature. This is a hard requirement from the project owner.
- Conventional commits, restricted to four types: `feat`, `fix`, `docs`, `refactor`.
- **Keep commit messages short** — a subject line is usually the whole message. Add a body only
  for a *why* the code cannot express, and then one or two lines, never paragraphs. The project
  owner asked for this explicitly after an over-long first commit.
- One branch per feature (`feat/habit-form`, `fix/streak-week-boundary`), integrated via PR.
  Never commit straight to the default branch. `gh` is not installed — push the branch and hand
  over the PR URL instead of trying to open it.
- `flutter analyze` must be clean before any commit.
- Domain logic is covered by pure unit tests — no widget test harness needed for `domain/`.

## Commands

```bash
flutter pub get                  # after any pubspec.yaml change
flutter run                      # attached device; flutter devices to list targets
flutter analyze                  # lint + type check (flutter_lints)
dart format lib test
flutter test
flutter test test/domain/services/streak_calculator_test.dart --plain-name 'breaks on missed day'
dart run build_runner build --delete-conflicting-outputs   # once freezed is added
flutter build apk | ipa
flutter clean                    # when build/ or .dart_tool/ state goes stale
```

Run everything from this directory (the Flutter project root), not the parent `Habit tracker/`.

## Notes

- Generated platform files (`GeneratedPluginRegistrant.*`, `ios/Flutter/Generated.xcconfig`) are
  rewritten by the Flutter tool — change `pubspec.yaml` and re-run `flutter pub get` instead.
- Lint overrides belong in `analysis_options.yaml`, not in scattered `// ignore:` comments.
- `docs/ARCHITECTURE.md` is written in Spanish (it is the owner's design-review document); code,
  identifiers and comments stay in English.
