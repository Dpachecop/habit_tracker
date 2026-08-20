import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/config/l10n/app_locales.dart';
import 'package:habit_tracker/config/theme/app_theme.dart';

/// Mounts a widget inside the app's real theme and localizations.
///
/// Widget tests that build their own bare `MaterialApp` end up testing a
/// different app: no Inter, no token colors, and `context.l10n` throwing. This
/// puts the widget under test in the same frame production gives it.
extension PumpApp on WidgetTester {
  /// Pumps [widget] as the body of a themed, localized scaffold.
  ///
  /// [locale] fixes the language, so a test can assert on Spanish copy without
  /// depending on the machine's settings.
  Future<void> pumpApp(
    Widget widget, {
    Locale locale = AppLocales.english,
    Brightness brightness = Brightness.light,
  }) async {
    await pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocales.delegates,
        supportedLocales: AppLocales.supported,
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        home: Scaffold(body: widget),
      ),
    );
    await pumpAndSettle();
  }
}
