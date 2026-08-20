import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';

/// Shorthand for reaching the translations from a widget.
extension L10nContext on BuildContext {
  /// The translations for the locale currently in effect.
  ///
  /// `AppLocalizations.of(context).homeTitle` at every call site is noise;
  /// `context.l10n.homeTitle` is the same lookup and reads like the sentence it
  /// produces.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
