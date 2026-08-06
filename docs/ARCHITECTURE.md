# Arquitectura — Habit Tracker

> Documento de diseño. Español para la discusión; **todo el código y sus comentarios van en inglés**.
> Estado: propuesta inicial, pendiente de aprobación. Nada de esto está implementado todavía.

---

## 1. Stack

| Área | Elección | Por qué |
|---|---|---|
| UI | Flutter 3.29.3 / Dart 3.7.2 | Ya fijado por el proyecto |
| Estado | `flutter_bloc` (Bloc + Cubit) | Pedido explícito; un bloc por contexto, independientes |
| Modelado | `freezed` + `equatable` | Uniones selladas (`HabitSchedule`) y `copyWith` sin boilerplate |
| Navegación | `go_router` | Rutas declarativas, redirects para el guard de auth futuro |
| Errores | `fpdart` (`Either<Failure, T>`) | Errores explícitos en la firma, no excepciones invisibles |
| Persistencia | Cloud Firestore (offline persistence ON) | Ver §6 — decisión abierta |
| Auth | `firebase_auth` — anónima primero, cuentas reales al final | Ver §6.2 |
| Gráficas | `fl_chart` | Reportes de línea por meta |
| IDs | `uuid` | Ids de cliente, permiten escritura offline |
| Fechas | `intl` | Formato y semana ISO |
| Tests | `flutter_test`, `bloc_test`, `mocktail` | El dominio se prueba sin Flutter |

Plataformas: **android + ios**. `web/` existe pero queda fuera de alcance hasta que se pida.

---

## 2. Capas

Tres capas, con la regla de dependencia apuntando **siempre hacia adentro**:

```
presentation  ──►  domain  ◄──  infrastructure
```

- **domain** — Dart puro. Cero imports de Flutter, Firebase o cualquier paquete de I/O.
  Contiene entidades, reglas de negocio (el motor de rachas), contratos abstractos y los `Failure`.
  Es la única capa que se puede leer para entender *qué hace* la app.
- **infrastructure** — implementa los contratos del dominio. Firestore, DTOs, mappers,
  traducción de excepciones a `Failure`. Es reemplazable: cambiar Firestore por SQLite
  no debe tocar ni una línea de `domain/` ni de `presentation/`.
- **presentation** — blocs, pantallas, widgets. Habla con el dominio a través de los contratos,
  nunca con Firestore directamente.

### 2.1 Estructura de carpetas

```
lib/
├── main.dart
├── config/
│   ├── di/                        # composition root: arma repos e inyecta con RepositoryProvider
│   ├── router/                    # go_router
│   ├── theme/                     # AppTheme, paleta de colores seleccionables
│   └── constants/
│
├── domain/
│   ├── entities/
│   │   ├── habit.dart             # la "meta"
│   │   ├── habit_entry.dart       # un check-in de un día
│   │   ├── habit_schedule.dart    # sealed: SpecificWeekdays | TimesPerPeriod
│   │   ├── schedule_version.dart  # schedule + effectiveFrom
│   │   ├── habit_category.dart
│   │   ├── time_window.dart       # horario del día u "all day"
│   │   ├── date_range.dart        # a→b o indeterminada
│   │   └── streak.dart            # current / longest / lastCompletedDate
│   ├── services/
│   │   └── streak_calculator.dart # ← el corazón. Función pura. Ver §4
│   ├── repositories/              # contratos abstractos
│   │   ├── habits_repository.dart
│   │   ├── entries_repository.dart
│   │   └── auth_repository.dart
│   ├── datasources/               # contratos abstractos
│   │   ├── habits_datasource.dart
│   │   └── entries_datasource.dart
│   └── failures/
│       └── failure.dart           # sealed Failure
│
├── infrastructure/
│   ├── datasources/
│   │   ├── firestore_habits_datasource.dart
│   │   └── firestore_entries_datasource.dart
│   ├── repositories/
│   │   ├── habits_repository_impl.dart
│   │   └── entries_repository_impl.dart
│   ├── models/                    # DTOs con toFirestore / fromFirestore
│   ├── mappers/                   # DTO ↔ entity
│   └── errors/
│       └── failure_mapper.dart    # Exception → Failure
│
└── presentation/
    ├── blocs/
    │   ├── habits/                # panel principal + toggle de check
    │   ├── habit_form/            # crear / editar (Cubit)
    │   ├── calendar/              # vista de año
    │   ├── reports/               # datos de las gráficas
    │   └── auth/                  # última fase
    ├── screens/
    │   ├── home/
    │   ├── habit_form/
    │   ├── reports/
    │   └── settings/
    └── widgets/
        ├── shared/
        ├── habit_card.dart
        └── year_heatmap.dart      # calendario anual custom
```

**Sobre los use cases:** no habrá una clase `UseCase` por operación. El 90% serían un passthrough
al repositorio y solo añaden ruido. La lógica que no es CRUD vive en **servicios de dominio**
(`StreakCalculator`) — que es donde realmente está el negocio. Si aparece una operación con
orquestación real de varios repositorios, ahí sí se crea un use case.

---

## 3. Modelo de dominio

### 3.1 `Habit`

```dart
class Habit {
  final String id;              // uuid generado en cliente
  final String name;
  final HabitCategory category;
  final int colorValue;         // ARGB, elegido por el usuario
  final List<ScheduleVersion> scheduleHistory; // ver 3.2 y 3.4
  final TimeWindow? timeWindow; // null = todo el día
  final DateRange range;        // start + end opcional (indeterminada)
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;        // nunca se borra duro: rompería el historial

  HabitSchedule scheduleOn(DateOnly date);  // el vigente en esa fecha
  HabitSchedule get currentSchedule;        // el último de la lista
}
```

Ojo: **no hay un campo `schedule` suelto**. El horario es una lista versionada, por la razón
que explica §3.4. Nada fuera de `Habit` debe recorrer `scheduleHistory` a mano; se usa
`scheduleOn(date)`.

### 3.2 `HabitSchedule` — la decisión de modelado clave

Los dos modos que describiste son estructuralmente distintos, así que son una unión sellada,
no flags sueltos:

```dart
sealed class HabitSchedule {}

/// Días concretos de la semana: lunes, miércoles, sábado.
/// "Diaria" es este caso con los 7 días — no necesita rama propia en el motor.
final class SpecificWeekdays extends HabitSchedule {
  final Set<Weekday> days;
}

/// N veces por período, sin importar qué días: 3/semana, 3/mes, 3/año.
final class TimesPerPeriod extends HabitSchedule {
  final int times;
  final SchedulePeriod period;  // week | month | year
}
```

Esto hace que el motor de rachas tenga exactamente **dos** ramas en vez de una maraña de
condicionales, y que agregar un modo nuevo mañana sea un caso más que el compilador te obliga
a cubrir.

### 3.3 `HabitEntry`

```dart
class HabitEntry {
  final String habitId;
  final DateOnly date;        // fecha local normalizada a medianoche
  final DateTime completedAt; // UTC, para auditoría
}
```

**Normalización de fechas:** todo cálculo usa la fecha *local* normalizada (`DateTime(y, m, d)`).
Se guarda además `completedAt` en UTC. Sin esto, un viaje de zona horaria o el cambio de horario
te corrompe las rachas. El id del documento es `{habitId}_{yyyy-MM-dd}`, lo que da unicidad e
idempotencia gratis: marcar dos veces el mismo día es la misma escritura.

Inicio de semana: **lunes (ISO 8601)**. Configurable más adelante.

### 3.4 Horario versionado

Cambiar el horario de una meta **no reescribe el pasado**. Una racha de 40 días ganada bajo
"lunes a viernes" sigue siendo válida aunque mañana la meta pase a "3 días/semana": los días
anteriores se evalúan con el horario que estaba vigente entonces, y los posteriores con el nuevo.

```dart
class ScheduleVersion {
  final HabitSchedule schedule;
  final DateOnly effectiveFrom;  // inclusive
}
```

`scheduleHistory` va ordenada, y su primer elemento arranca en `range.start`. El
`StreakCalculator` pregunta `habit.scheduleOn(date)` en cada paso, nunca asume un horario único.

**Cuándo entra en vigor un cambio:**

- `SpecificWeekdays` → al día siguiente. El día en curso ya se estaba jugando con las reglas viejas.
- `TimesPerPeriod` → al inicio del **siguiente período**. Cambiar de 3 a 5 días a mitad de semana
  dejaría esa semana con un requisito imposible o ya cumplido de forma arbitraria; el período en
  curso se cierra con las reglas con las que empezó.

Esto es también lo que permite la válvula de escape de §3.5: si quieres cumplir más días de los
pactados, subes el número en la meta y el cambio aplica desde el período siguiente.

### 3.5 Regla de marcado: no se puede sobrecumplir

Una meta define **cuánto** hay que hacer, y la app no deja excederlo. Si te pusiste 3 días a la
semana, no puedes tener 5 marcados: en el papel vas sobrado, pero la meta que te pusiste era otra.

- `SpecificWeekdays` → solo se puede marcar en días programados. El check ni siquiera aparece
  habilitado un martes si la meta es lunes/miércoles/sábado.
- `TimesPerPeriod` → se puede marcar cualquier día, pero el check se deshabilita al llegar a
  `times` en el período actual.

Si el usuario quiere hacer más, **edita la meta y sube el número** — con la vigencia de §3.4.

El dominio es quien decide, no la UI: `HabitEntry` solo se crea si el dominio lo autoriza, y un
intento de exceso devuelve `ValidationFailure`. La UI deshabilita el botón para que ese error
casi nunca ocurra, pero la regla no vive ahí.

Consecuencia útil: un período cerrado exitoso tiene **exactamente** `times` entradas, nunca más.
Eso simplifica el conteo de rachas del modo B.

---

## 4. Motor de rachas (`StreakCalculator`)

Función pura: `(Habit, List<HabitEntry>, DateTime today) → Streak`. Sin I/O, sin Flutter.
Es lo primero que se implementa y lo que más tests va a tener.

### Modo A — `SpecificWeekdays`

- **Día programado** = su día de semana está en `days` **y** cae dentro de `range`.
- Se camina hacia atrás desde hoy:
  - Día programado y completado → suma 1, sigue.
  - Día programado y **no** completado → **corta**.
  - Día no programado → transparente. Por §3.5 ni siquiera puede tener entrada.
- **Hoy no rompe la racha.** El día está abierto hasta la medianoche; si es un día programado y
  aún no lo marcas, la racha se mantiene y simplemente no cuenta todavía.

Tu ejemplo: meta lunes–viernes, cumple lunes y martes, falla miércoles → el miércoles es día
programado sin entrada → racha cortada. ✓

### Modo B — `TimesPerPeriod`

- Las fechas se agrupan en períodos calendario (semana ISO / mes / año), recortados por `range`.
- Un período **cerrado** es exitoso si `completions == times`. Por §3.5 nunca puede haber más,
  así que "cumplido" y "exactamente cumplido" son lo mismo.
- El período **actual está abierto**: nunca corta la racha, aunque todavía lleves 0 de 3.
- La racha se mide **en días cumplidos**, no en períodos:
  `racha = completions del período abierto + (times × períodos cerrados exitosos consecutivos hacia atrás)`.
- Corta en cuanto un período cerrado queda por debajo de `times`.

Tu ejemplo: 3 días/semana, cumple los 3 → racha 3. La semana siguiente cumple los 3 → racha 6. ✓

`longestStreak` es el mismo algoritmo recorriendo todo el historial y guardando el máximo.

**La racha nunca se persiste como campo**, se deriva. Un contador guardado en base de datos se
desincroniza en cuanto edites una entrada vieja o cambies el horario de la meta.

### Horarios mixtos en una misma racha

Como el horario está versionado (§3.4), una racha puede atravesar un cambio de reglas. El cálculo
no distingue: en cada paso hacia atrás usa `habit.scheduleOn(date)` y aplica el modo A o B que
correspondiera **ese día**. Una racha de 40 días bajo "lunes a viernes" sobrevive al cambio a
"3 días/semana" y sigue creciendo con las reglas nuevas.

Esto obliga a un detalle en modo B: al agrupar en períodos hay que cortar los buckets también en
las fronteras de vigencia, para no mezclar medio período con `times = 3` y medio con `times = 5`.
Por eso §3.4 hace que los cambios de `TimesPerPeriod` entren en vigor en el siguiente período —
así frontera de vigencia y frontera de período siempre coinciden, y este caso desaparece.

---

## 5. Manejo de errores

```dart
sealed class Failure {
  final String code;      // clave estable, no texto de UI
  final Object? cause;
}

final class NetworkFailure   extends Failure {}
final class NotFoundFailure  extends Failure {}
final class PermissionFailure extends Failure {}
final class ValidationFailure extends Failure {}  // p.ej. marcar por encima del límite (§3.5)
final class CacheFailure     extends Failure {}
final class UnknownFailure   extends Failure {}
```

Flujo:

1. **infrastructure** captura la excepción concreta (`FirebaseException`, `TimeoutException`…)
   y la traduce en `failure_mapper.dart`.
2. **repositorio** devuelve `Either<Failure, T>` — el error es parte de la firma, no una sorpresa.
3. **bloc** hace `fold` y emite un estado con el `Failure` adentro.
4. **UI** convierte `Failure → String` con un mapper de presentación.

Los `Failure` **no llevan texto para el usuario**, solo un `code`. Así el dominio no sabe de idiomas
y meter i18n después no obliga a tocarlo.

---

## 6. Persistencia — decisión abierta

### 6.1 Las dos opciones

**Opción A — Firestore con persistencia offline activada (recomendada)**

Firestore ya trae caché local y cola de escrituras offline. Marcas una meta en el metro sin señal,
se guarda local y sincroniza sola al volver la red. El volumen de datos aquí es minúsculo
(unos miles de documentos en años de uso), así que los reportes se calculan en memoria en Dart
sin problema.

- ✅ Cero código de sincronización
- ✅ Multi-dispositivo desde el día uno
- ⚠️ Agregaciones complejas limitadas — irrelevante a esta escala

**Opción B — Base local (Drift/SQLite) + sync manual a Firestore**

- ✅ Control total, consultas SQL para reportes
- ❌ Tienes que escribir un motor de sincronización: resolución de conflictos, tombstones,
  marcas de "pendiente de subir". Es fácilmente la parte más grande del proyecto.

**Mi recomendación: A.** Y como los contratos viven en `domain/datasources/`, migrar a B después
es cambiar una implementación, sin tocar dominio ni UI. La abstracción existe justamente para que
esta decisión no sea irreversible.

### 6.2 Auth anónima desde el principio

Pediste el login como *última* feature, pero los datos deben estar en base desde ya. La forma
limpia de tener las dos cosas:

1. Al primer arranque, `signInAnonymously()` → hay un `uid` real sin que el usuario vea nada.
2. Todo se guarda bajo ese `uid` desde el día uno.
3. Cuando llegue la fase de login, `linkWithCredential()` **convierte** la cuenta anónima en una
   cuenta real **conservando el uid y todos los datos**.

Así la pantalla de login sigue siendo lo último que se construye, pero nada de lo guardado antes
se pierde ni hay que migrarlo.

### 6.3 Modelo en Firestore

```
users/{uid}
  ├── habits/{habitId}                     # documento de meta
  └── entries/{habitId}_{yyyy-MM-dd}       # id determinista → idempotente
        { habitId, date: "2026-08-06", completedAt: <ts> }
```

Colección de entries **plana** (no anidada bajo cada habit): el panel principal necesita
"todas las entradas de hoy" (query por `date`) y los reportes necesitan "todas las de esta meta en
un rango" (query por `habitId` + `date`). Plana resuelve ambas sin `collectionGroup`.

Reglas de seguridad:

```
match /users/{uid}/{document=**} {
  allow read, write: if request.auth != null && request.auth.uid == uid;
}
```

---

## 7. Blocs

Independientes, cada uno con una responsabilidad:

| Bloc | Tipo | Responsabilidad |
|---|---|---|
| `HabitsBloc` | Bloc | Lista de metas + estado de cumplimiento de hoy + toggle del check |
| `HabitFormCubit` | Cubit | Estado del formulario de crear/editar + validación |
| `CalendarCubit` | Cubit | Año seleccionado y datos del heatmap |
| `ReportsBloc` | Bloc | Series por meta para las gráficas |
| `AuthBloc` | Bloc | Sesión (última fase) |
| `ThemeCubit` | Cubit | Tema claro/oscuro |

`HabitsBloc` se alimenta de un **stream** del repositorio (`watchHabits()`), no de un `get` puntual.
Firestore emite cambios en vivo y la UI se mantiene sola sin refrescos manuales.

El toggle del check es **optimista**: la UI cambia de inmediato y revierte si la escritura falla.
Marcar un hábito tiene que sentirse instantáneo.

`HabitsBloc` expone además, por cada meta, si hoy **se puede** marcar (§3.5): día no programado o
cupo del período agotado. La `HabitCard` usa ese dato para deshabilitar el check.

---

## 8. Pantallas

1. **Home** — lista de `HabitCard` (nombre, categoría, racha actual, check en el color de la meta)
   + `YearHeatmap` abajo: cuadrícula estilo GitHub del año, días cumplidos en el color de la meta,
   el resto en gris.
   El check se deshabilita cuando hoy no toca o ya se llenó el cupo del período (§3.5), con un
   texto que diga por qué: "hoy no toca" o "3/3 esta semana".
   El heatmap anual es **widget propio** — `table_calendar` es mensual y no sirve para esto.
2. **Habit form** — nombre, color, categoría, tipo de horario (días concretos vs N por período),
   ventana horaria u "todo el día", rango de fechas o indeterminada.
   Al **editar** el horario no se sobrescribe: se añade un `ScheduleVersion` (§3.4). El formulario
   avisa desde cuándo aplica el cambio, para que quede claro que la racha vigente no se pierde.
3. **Reports** — una gráfica de línea por meta (`fl_chart`): eje X tiempo, eje Y días cumplidos.
   Selector de rango (mes / 6 meses / año).
4. **Settings** — tema, exportación de datos, y más adelante la cuenta.

---

## 9. Convenciones

- **Comentarios en inglés en toda clase y función**, con dartdoc `///`. Explican el *porqué*,
  no reescriben la firma.
- Conventional commits, solo cuatro tipos: `feat`, `fix`, `docs`, `refactor`.
- **Commits cortos.** Una línea de asunto y ya. Sin cuerpo salvo que haya un *porqué* que el
  código no puede contar, y en ese caso una o dos líneas, nunca párrafos.
- Una rama por feature: `feat/habit-form`, `fix/streak-week-boundary`. Integración vía PR.
- `flutter analyze` limpio antes de cada commit.
- El dominio se prueba con tests unitarios puros. `StreakCalculator` va con tabla de casos borde:
  cambio de año, semana ISO a caballo entre meses, metas con rango cerrado, período abierto,
  y racha que atraviesa un cambio de horario (§3.4).

---

## 10. Roadmap por iteraciones

Cada fase = una rama = un PR.

| # | Fase | Contenido |
|---|---|---|
| 0 | Setup | git init + remoto, dependencias, estructura de carpetas, tema base |
| 1 | Dominio | Entidades, `HabitSchedule`, `ScheduleVersion`, regla de marcado (§3.5), `Failure`, `StreakCalculator` **+ sus tests**. Dart puro, sin UI |
| 2 | Infraestructura | Firebase project, auth anónima, Firestore datasources, repos, mappers |
| 3 | Home | `HabitsBloc`, `HabitCard`, toggle optimista del check |
| 4 | Formulario | Crear/editar meta con todas las opciones de horario |
| 5 | Calendario | `YearHeatmap` y su integración en Home |
| 6 | Reportes | `ReportsBloc` + gráficas `fl_chart` |
| 7 | Cuenta | Login real vía `linkWithCredential`, exportación de reportes |

La fase 1 es deliberadamente lo primero: si el motor de rachas está bien y probado, todo lo demás
es pintar datos. Si está mal, la app entera miente.
