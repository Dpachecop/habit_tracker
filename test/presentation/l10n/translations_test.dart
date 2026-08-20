import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/config/l10n/app_locales.dart';
import 'package:habit_tracker/domain/entities/habit_category.dart';
import 'package:habit_tracker/domain/failures/failure.dart';
import 'package:habit_tracker/l10n/generated/app_localizations.dart';
import 'package:habit_tracker/presentation/l10n/domain_labels.dart';
import 'package:habit_tracker/presentation/l10n/failure_messages.dart';

/// Keeps the two languages honest.
///
/// A translation module fails quietly: the string is simply missing, or falls
/// back to the other language, and nobody notices until a user does. These
/// tests turn every one of those into a red build — a code with no sentence, a
/// category with no label, an `.arb` key added to one file and not the other.
void main() {
  /// Loads the translations for a locale outside of any widget tree.
  ///
  /// The generated delegate resolves synchronously, so this needs no pumping.
  Future<AppLocalizations> load(Locale locale) =>
      AppLocalizations.delegate.load(locale);

  /// Every non-metadata key in an `.arb` file.
  Set<String> keysOf(String fileName) {
    final Map<String, dynamic> arb =
        jsonDecode(File('lib/l10n/$fileName').readAsStringSync())
            as Map<String, dynamic>;
    return arb.keys.where((String key) => !key.startsWith('@')).toSet();
  }

  test('the app offers exactly the locales it has translations for', () {
    // Adding an .arb without registering it, or the reverse, is silent
    // otherwise: the language exists but nothing ever selects it.
    expect(
      AppLocales.supported.toSet(),
      AppLocalizations.supportedLocales.toSet(),
    );
  });

  test('Spanish is the fallback for a device that speaks neither', () {
    // Order, not membership. Flutter takes the first supported locale when it
    // cannot match the device, and this app's users are Spanish speakers.
    expect(AppLocales.supported.first, AppLocales.spanish);
  });

  test('both .arb files define the same keys', () {
    final Set<String> english = keysOf('app_en.arb');
    final Set<String> spanish = keysOf('app_es.arb');

    expect(
      spanish.difference(english),
      isEmpty,
      reason: 'keys in Spanish with no English original',
    );
    expect(
      english.difference(spanish),
      isEmpty,
      reason: 'keys never translated into Spanish',
    );
  });

  for (final Locale locale in AppLocales.supported) {
    group('${locale.languageCode} —', () {
      test('every failure code has its own sentence', () async {
        final AppLocalizations l10n = await load(locale);
        final List<String> codes = <String>[
          FailureCodes.network,
          FailureCodes.notFound,
          FailureCodes.permission,
          FailureCodes.cache,
          FailureCodes.unknown,
          FailureCodes.completionArchived,
          FailureCodes.completionOutsideRange,
          FailureCodes.completionFutureDate,
          FailureCodes.completionAlreadyRecorded,
          FailureCodes.completionNotScheduled,
          FailureCodes.completionQuotaReached,
        ];

        final Set<String> messages = <String>{};
        for (final String code in codes) {
          final String message = l10n.messageForFailureCode(code);
          expect(message.trim(), isNotEmpty, reason: 'empty message for $code');
          // Distinctness is what catches a code silently falling through to
          // the generic message — the failure mode this whole test exists for.
          expect(
            messages.add(message),
            isTrue,
            reason: '$code reuses another code\'s message: "$message"',
          );
        }
        expect(messages.length, codes.length);
      });

      test('an unknown code lands on the generic message', () async {
        final AppLocalizations l10n = await load(locale);
        expect(
          l10n.messageForFailureCode('nope.not.a.code'),
          l10n.errorUnknown,
        );
      });

      test('a Failure object resolves to the same text as its code', () async {
        final AppLocalizations l10n = await load(locale);
        expect(
          l10n.messageForFailure(const NetworkFailure()),
          l10n.errorNetwork,
        );
        expect(
          l10n.messageForFailure(
            const ValidationFailure(code: FailureCodes.completionNotScheduled),
          ),
          l10n.errorCompletionNotScheduled,
        );
      });

      test('every habit category has its own label', () async {
        final AppLocalizations l10n = await load(locale);
        final Set<String> labels = <String>{};

        for (final HabitCategory category in HabitCategory.values) {
          final String label = l10n.labelForCategory(category);
          expect(label.trim(), isNotEmpty, reason: 'empty label for $category');
          expect(
            labels.add(label),
            isTrue,
            reason: '$category reuses another label: "$label"',
          );
        }
      });

      test('quota progress places both numbers', () async {
        final AppLocalizations l10n = await load(locale);
        for (final String text in <String>[
          l10n.quotaProgressWeek(2, 3),
          l10n.quotaProgressMonth(2, 3),
          l10n.quotaProgressYear(2, 3),
        ]) {
          expect(text, contains('2'));
          expect(text, contains('3'));
        }
      });
    });
  }

  test('the strings actually differ between the two languages', () async {
    // Guards against a copy-pasted .arb where the translation never happened.
    final AppLocalizations english = await load(AppLocales.english);
    final AppLocalizations spanish = await load(AppLocales.spanish);

    expect(spanish.homeTitle, isNot(english.homeTitle));
    expect(spanish.errorUnknown, isNot(english.errorUnknown));
    expect(
      spanish.labelForCategory(HabitCategory.health),
      isNot(english.labelForCategory(HabitCategory.health)),
    );
  });
}
