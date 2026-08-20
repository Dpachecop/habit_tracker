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
  String get errorNetwork => 'Sin conexión. Tus cambios se sincronizarán cuando vuelvas a tener red.';

  @override
  String get errorNotFound => 'No encontramos eso.';

  @override
  String get errorPermission => 'No tienes acceso a eso.';

  @override
  String get errorCache => 'No se pudieron leer los datos guardados en este dispositivo.';

  @override
  String get errorUnknown => 'Algo salió mal.';

  @override
  String get errorCompletionArchived => 'Esta meta está archivada.';

  @override
  String get errorCompletionOutsideRange => 'Ese día queda fuera del rango de fechas de la meta.';

  @override
  String get errorCompletionFutureDate => 'No puedes marcar un día que todavía no ha pasado.';

  @override
  String get errorCompletionAlreadyRecorded => 'Ya marcaste este día.';

  @override
  String get errorCompletionNotScheduled => 'Esta meta no toca ese día.';

  @override
  String get errorCompletionQuotaReached => 'Ya cumpliste el objetivo de este período.';

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
  String get homeGreetingMorning => 'Buenos días.';

  @override
  String get homeGreetingAfternoon => 'Buenas tardes.';

  @override
  String get homeGreetingEvening => 'Buenas noches.';

  @override
  String homeHabitsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Te quedan $count metas por cumplir hoy.',
      one: 'Te queda 1 meta por cumplir hoy.',
      zero: 'No te queda nada para hoy. Bien hecho.',
    );
    return '$_temp0';
  }

  @override
  String get homeNothingDueToday => 'Hoy no toca ninguna meta.';

  @override
  String get homeEmptyHint => 'Crea tu primera meta para empezar una racha.';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días de racha',
      one: '1 día de racha',
    );
    return '$_temp0';
  }

  @override
  String get streakNone => 'Sin racha todavía';

  @override
  String get scheduleDaily => 'Diaria';

  @override
  String scheduleTimesPerWeek(int times) {
    String _temp0 = intl.Intl.pluralLogic(
      times,
      locale: localeName,
      other: '$times veces por semana',
      two: 'Dos veces por semana',
      one: 'Una vez por semana',
    );
    return '$_temp0';
  }

  @override
  String scheduleTimesPerMonth(int times) {
    String _temp0 = intl.Intl.pluralLogic(
      times,
      locale: localeName,
      other: '$times veces al mes',
      two: 'Dos veces al mes',
      one: 'Una vez al mes',
    );
    return '$_temp0';
  }

  @override
  String scheduleTimesPerYear(int times) {
    String _temp0 = intl.Intl.pluralLogic(
      times,
      locale: localeName,
      other: '$times veces al año',
      two: 'Dos veces al año',
      one: 'Una vez al año',
    );
    return '$_temp0';
  }

  @override
  String get navHome => 'Inicio';

  @override
  String get navAnalytics => 'Analítica';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get navProfile => 'Perfil';

  @override
  String get comingSoon => 'Muy pronto.';

  @override
  String get formTitleCreate => 'Nueva meta';

  @override
  String get formTitleEdit => 'Editar meta';

  @override
  String get formSave => 'Guardar';

  @override
  String get formSavedCreate => 'Meta creada.';

  @override
  String get formSavedEdit => 'Cambios guardados.';

  @override
  String get formNameLabel => 'Nombre';

  @override
  String get formNameHint => 'Meditar en la mañana';

  @override
  String get formNameRequired => 'Ponle un nombre a tu meta.';

  @override
  String get formCategoryLabel => 'Categoría';

  @override
  String get formColorLabel => 'Color';

  @override
  String get formScheduleLabel => 'Con qué frecuencia';

  @override
  String get formScheduleModeWeekdays => 'Días concretos';

  @override
  String get formScheduleModeTimes => 'Un número de veces';

  @override
  String get formWeekdaysRequired => 'Elige al menos un día.';

  @override
  String get formEveryDay => 'Todos los días';

  @override
  String get formTimesLabel => 'Veces';

  @override
  String get formPeriodLabel => 'Por';

  @override
  String get formPeriodWeek => 'Semana';

  @override
  String get formPeriodMonth => 'Mes';

  @override
  String get formPeriodYear => 'Año';

  @override
  String formTimesTooMany(int max) {
    return 'Máximo $max — un día solo se puede cumplir una vez.';
  }

  @override
  String get formTimeWindowLabel => 'Franja del día';

  @override
  String get formAllDay => 'Todo el día';

  @override
  String get formTimeFrom => 'Desde';

  @override
  String get formTimeTo => 'Hasta';

  @override
  String get formTimeWindowInvalid => 'El fin tiene que ser después del inicio.';

  @override
  String get formDatesLabel => 'Fechas';

  @override
  String get formStartDate => 'Empieza';

  @override
  String get formEndDate => 'Termina';

  @override
  String get formNoEndDate => 'Sin fecha de fin';

  @override
  String get formEndBeforeStart => 'El fin no puede ser antes del inicio.';

  @override
  String get formScheduleChangeTomorrow => 'Los días nuevos aplican desde mañana. Todo hasta hoy conserva el horario anterior, así que la racha que ya ganaste está a salvo.';

  @override
  String get formScheduleChangeToday => 'El objetivo nuevo aplica desde hoy. Los días que ya cumpliste siguen contando para él.';

  @override
  String get formUnreachableTitle => 'Este período ya no se alcanza';

  @override
  String formUnreachableWeek(int missing, int daysLeft) {
    return 'Te faltarían $missing esta semana y solo quedan $daysLeft días. Si guardas, la racha se corta al terminar la semana.';
  }

  @override
  String formUnreachableMonth(int missing, int daysLeft) {
    return 'Te faltarían $missing este mes y solo quedan $daysLeft días. Si guardas, la racha se corta al terminar el mes.';
  }

  @override
  String formUnreachableYear(int missing, int daysLeft) {
    return 'Te faltarían $missing este año y solo quedan $daysLeft días. Si guardas, la racha se corta al terminar el año.';
  }

  @override
  String get formUnreachableConfirm => 'Guardar de todos modos';

  @override
  String get formBack => 'Volver';

  @override
  String get formArchive => 'Archivar meta';

  @override
  String get formArchiveExplain => 'Sale de tu lista pero conserva su historial. No se borra nada.';

  @override
  String get formArchiveConfirmTitle => '¿Archivar esta meta?';

  @override
  String get formArchiveConfirm => 'Archivar';

  @override
  String get formArchived => 'Meta archivada.';

  @override
  String heatmapSummary(int days, int completed) {
    return 'Últimos $days días, $completed cumplidos.';
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
