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
scope). Bundle ids are still the defaults, and they differ per platform: `com.example.habit_tracker`
on android, `com.example.habitTracker` on ios — Apple does not allow underscores. `minSdk` is 23,
raised from Flutter's 21 because `firebase_auth` requires it.

Firebase is connected (project `habit-tracker-f30b61`), but its three generated config files are
**gitignored** — see `docs/STATUS.md` for the one command that regenerates them on a new machine.
`flutter analyze` and `flutter test` do not need them; only a device build does.

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
  in `SpecificWeekdays`; `TimesPerPeriod` caps at the period target. The domain enforces this and
  returns `ValidationFailure`; the UI only disables the button as a courtesy.
- A `TimesPerPeriod` period's target is the **highest `times` in force during that period**, not
  the current one. That single rule handles both raising and lowering the goal mid-period, and
  guarantees an already-written entry never becomes retroactively illegal.
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
- **Never hard-code user-facing text.** Every string the user reads lives in `lib/l10n/app_en.arb`
  and `lib/l10n/app_es.arb`, and reaches the screen through `context.l10n`. Domain→text mappings
  (failure codes, category names) belong in `lib/presentation/l10n/`. See `ARCHITECTURE.md` §11.

## Commands

```bash
flutter pub get                  # after any pubspec.yaml change
flutter run                      # attached device; flutter devices to list targets
flutter analyze                  # lint + type check (flutter_lints)
dart format lib test
flutter test
flutter test test/domain/services/streak_calculator_test.dart --plain-name 'breaks on missed day'
flutter gen-l10n                 # after editing any lib/l10n/*.arb (pub get also runs it)
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
