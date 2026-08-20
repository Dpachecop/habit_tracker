import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../l10n/generated/app_localizations.dart';

/// The languages the app ships in, and the delegates that resolve them.
///
/// Two, on purpose: Spanish because it is the owner's language, English
/// because the codebase already is. Adding a third is one `.arb` file plus one
/// entry in [supported] — and a test fails if you do only one of the two.
///
/// This lives in `config/` rather than in `l10n/` because it is composition:
/// the generated `AppLocalizations` knows the strings, this knows what the
/// running app offers.
abstract final class AppLocales {
  /// Spanish, no country. Regional variants would multiply the files for
  /// differences this app does not have.
  static const Locale spanish = Locale('es');

  /// English, no country, for the same reason.
  static const Locale english = Locale('en');

  /// Supported languages, **most preferred first**.
  ///
  /// Order matters: Flutter falls back to the first entry when the device
  /// speaks none of them, and this app's users are Spanish speakers. Handing a
  /// Japanese phone an English UI would be the accident of alphabetical order,
  /// not a decision.
  static const List<Locale> supported = <Locale>[spanish, english];

  /// Everything `MaterialApp` needs to resolve [supported].
  ///
  /// The Flutter delegates are what translate the framework's own widgets —
  /// date pickers, the text-selection menu — so leaving them out would give a
  /// Spanish app an English "Paste".
  static const List<LocalizationsDelegate<Object>> delegates =
      <LocalizationsDelegate<Object>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ];
}
