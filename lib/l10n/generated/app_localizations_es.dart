// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Habit Tracker';

  @override
  String get homeTitle => 'Metas';

  @override
  String get homeEmpty => 'Todavía no tienes metas.';

  @override
  String get errorNetwork =>
      'Sin conexión. Tus cambios se sincronizarán cuando vuelvas a tener red.';

  @override
  String get errorNotFound => 'No encontramos eso.';

  @override
  String get errorPermission => 'No tienes acceso a eso.';

  @override
  String get errorCache =>
      'No se pudieron leer los datos guardados en este dispositivo.';

  @override
  String get errorUnknown => 'Algo salió mal.';

  @override
  String get errorCompletionArchived => 'Esta meta está archivada.';

  @override
  String get errorCompletionOutsideRange =>
      'Ese día queda fuera del rango de fechas de la meta.';

  @override
  String get errorCompletionFutureDate =>
      'No puedes marcar un día que todavía no ha pasado.';

  @override
  String get errorCompletionAlreadyRecorded => 'Ya marcaste este día.';

  @override
  String get errorCompletionNotScheduled => 'Esta meta no toca ese día.';

  @override
  String get errorCompletionQuotaReached =>
      'Ya cumpliste el objetivo de este período.';

  @override
  String get checkDisabledNotToday => 'Hoy no toca';

  @override
  String quotaProgressWeek(int completed, int target) {
    return '$completed/$target esta semana';
  }

  @override
  String quotaProgressMonth(int completed, int target) {
    return '$completed/$target este mes';
  }

  @override
  String quotaProgressYear(int completed, int target) {
    return '$completed/$target este año';
  }

  @override
  String get categoryHealth => 'Salud';

  @override
  String get categoryFitness => 'Ejercicio';

  @override
  String get categoryMind => 'Mente';

  @override
  String get categoryLearning => 'Aprendizaje';

  @override
  String get categoryWork => 'Trabajo';

  @override
  String get categoryFinance => 'Finanzas';

  @override
  String get categorySocial => 'Social';

  @override
  String get categoryHome => 'Hogar';

  @override
  String get categoryCreativity => 'Creatividad';

  @override
  String get categoryOther => 'Otros';
}
