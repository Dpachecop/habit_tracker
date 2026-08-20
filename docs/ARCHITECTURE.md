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
│   │   ├── habit_color_slot.dart  # enum de paleta, sin dart:ui
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
  final HabitColorSlot colorSlot; // slot de paleta, no un ARGB — ver 3.6
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

- `SpecificWeekdays` → al día siguiente. Los días ya transcurridos conservan sus reglas; si no,
  añadir un martes te rompería retroactivamente una racha por un martes que nunca te tocó.
- `TimesPerPeriod` → **el objetivo de un período es el mayor `times` vigente durante ese período.**

Esa única regla cubre los dos sentidos del cambio:

| Cambio | Semana en curso | Semana siguiente |
|---|---|---|
| 3 → 5 el miércoles | pasa a exigir **5**; los días ya marcados cuentan, faltan 2 | 5 |
| 5 → 3 el miércoles | sigue en **5**; los 5 días ya marcados siguen siendo válidos | 3 |

El caso de bajada tiene que funcionar así por §3.5: si el cupo bajara a 3 de inmediato, las 5
entradas ya registradas quedarían por encima del límite y serían ilegales de forma retroactiva.
Tomando el máximo, ninguna entrada ya escrita deja de ser válida nunca.

Y como el `effectiveFrom` de un cambio es siempre hoy, esto **solo puede afectar al período
abierto**. Los períodos cerrados calculan su máximo con las versiones que estuvieran vigentes
entonces y ya no se mueven.

> **Efecto a vigilar:** subir el objetivo cuando quedan pocos días del período puede volverlo
> inalcanzable (pasar de 3 a 5 un sábado) y garantizar el corte de la racha. La regla se queda
> como está — la pediste así —, pero el formulario debe avisar: *"esta semana ya no alcanzas los
> 5 días"*, y que el usuario decida. Quemar una racha en silencio no es aceptable.

### 3.5 Regla de marcado: no se puede sobrecumplir

Una meta define **cuánto** hay que hacer, y la app no deja excederlo. Si te pusiste 3 días a la
semana, no puedes tener 5 marcados: en el papel vas sobrado, pero la meta que te pusiste era otra.

- `SpecificWeekdays` → solo se puede marcar en días programados. El check ni siquiera aparece
  habilitado un martes si la meta es lunes/miércoles/sábado.
- `TimesPerPeriod` → se puede marcar cualquier día, pero el check se deshabilita al llegar al
  objetivo del período actual (el mayor `times` vigente en él, §3.4).

Si el usuario quiere hacer más, **edita la meta y sube el número** — con la vigencia de §3.4.

El dominio es quien decide, no la UI: `HabitEntry` solo se crea si el dominio lo autoriza, y un
intento de exceso devuelve `ValidationFailure`. La UI deshabilita el botón para que ese error
casi nunca ocurra, pero la regla no vive ahí.

Consecuencia útil: un período cerrado exitoso tiene **exactamente** `times` entradas, nunca más.
Eso simplifica el conteo de rachas del modo B.

### 3.6 El color es un slot, no un ARGB

`Habit` guarda un `HabitColorSlot` (un enum de 8 valores), no el color resuelto. Dos razones:

1. **Modo oscuro.** Cada slot tiene un paso propio para fondo claro y otro para fondo oscuro; no
   son el mismo color aclarado. Si guardáramos el ARGB, la meta quedaría congelada en el tema que
   estuviera activo al crearla y en el otro se vería mal.
2. **El dominio no importa `dart:ui`.** Un enum es un valor puro; `Color` no.

Resolver slot → color es trabajo de presentación (`HabitPalette`).

La paleta se validó con el verificador de visualización de datos contra las dos superficies:
banda de luminosidad, piso de croma, separación entre slots adyacentes bajo daltonismo
(peor ΔE 9.1 claro / 8.4 oscuro, objetivo ≥ 8) y separación en visión normal (peor 19.6 / 19.3,
piso ≥ 15). **El orden del enum es parte de la garantía**, no cosmético: los slots contiguos son
los que se comparan. Una meta nueva debería tomar el siguiente slot libre en ese orden, y editar
un hex suelto invalida la validación de sus vecinos.

Tres slots en modo claro (aqua, amarillo, magenta) quedan por debajo de 3:1 de contraste. Es
aceptable **solo** porque el color nunca identifica una meta por sí solo: siempre va junto a su
nombre. Cualquier superficie nueva que pinte el color sin la etiqueta tiene que añadir borde,
textura o texto.

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

En modo B los buckets **no se parten** en las fronteras de vigencia. Un período es un período
entero, y su objetivo es el mayor `times` vigente en él (§3.4). Así, una semana en la que pasaste
de 3 a 5 se evalúa completa contra 5, contando también los días que marcaste antes del cambio.

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

Las reglas viven en `firestore.rules` y los índices compuestos en `firestore.indexes.json`, ambos
en la raíz del proyecto y versionados. Se despliegan con
`firebase deploy --only firestore:rules,firestore:indexes`.

**El índice `(habitId, date)` no es una optimización**: Firestore rechaza directamente una consulta
que combine igualdad en `habitId` con rango en `date` si no existe, así que sin él los reportes no
funcionan.

Las rutas se construyen en un único sitio — `infrastructure/datasources/firestore_paths.dart` —
porque tienen que coincidir exactamente con las reglas de arriba. Un segmento distinto no da datos
incorrectos: da `permission-denied` en producción y en ningún otro lado.

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
- **Ningún texto de usuario escrito en el código**: va en los `.arb`, en los dos idiomas. Ver §11.
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

---

## 11. Idiomas

La app se entrega en **español e inglés**. No es una traducción que se añade al final: es una
restricción de arquitectura, porque decide dónde puede vivir el texto.

### 11.1 La regla

**Ningún string visible para el usuario se escribe en el código.** Vive en `lib/l10n/*.arb`, en
los dos idiomas, y llega a pantalla por la clase generada `AppLocalizations`.

Esto no es una preferencia de estilo: es lo que hace posible que `Failure` lleve solo un `code`
(§5) y que el dominio no sepa de idiomas. Si un widget escribe `Text('Hoy no toca')`, la regla se
rompió en los dos sentidos — el texto quedó fuera del catálogo y el idioma se coló en la UI.

### 11.2 Dónde vive cada pieza

```
lib/l10n/
├── app_en.arb            # plantilla: las claves y sus descripciones, en inglés
├── app_es.arb            # traducción
└── generated/            # AppLocalizations — generado, versionado en git
lib/config/l10n/
└── app_locales.dart      # qué idiomas ofrece la app y en qué orden, + delegates
lib/presentation/l10n/
├── l10n_extensions.dart  # context.l10n
├── failure_messages.dart # FailureCode → frase. La otra mitad de §5
└── domain_labels.dart    # HabitCategory → etiqueta, cupo de período → "2/3 esta semana"
```

Los mapeos `dominio → texto` son de **presentación**, nunca del dominio. El dominio nombra sus
valores con identificadores en inglés y no sabe cómo se muestran.

La plantilla es la inglesa porque las claves y sus descripciones son código, y el código va en
inglés (§9). El **fallback en tiempo de ejecución sí es español**: `AppLocales.supported` va
ordenado `[es, en]`, y Flutter toma el primero cuando el dispositivo no habla ninguno. El orden es
una decisión, no el resultado alfabético.

### 11.3 Qué está probado

`test/presentation/l10n/translations_test.dart` convierte en build roja los tres fallos silenciosos
de un módulo de idiomas:

- una clave que existe en un `.arb` y no en el otro;
- un `FailureCode` o una `HabitCategory` sin frase propia — se comprueba que sean **distintas**,
  porque una clave olvidada cae al mensaje genérico y eso, sin este test, no se nota;
- un idioma declarado en `AppLocales` que no tiene traducciones, o al revés.

### 11.4 Pendiente

El idioma **sigue al del dispositivo**. El selector manual llega con la pantalla de ajustes, que es
donde además habrá dónde persistir la elección; montar hoy un `LocaleCubit` sin UI ni persistencia
sería código muerto.

---

## 12. Diseño visual

El sistema visual es **Serene Habit**, definido por el dueño en `docs/design/DESIGN.md` con capturas
en `docs/design/screens/`. Inter, base de 4px, márgenes de 20, esquinas de 16, sombras ambientales.
Los tokens se traducen a código en `config/theme/` y **no se re-inventan en los widgets**: un padding
de 13px es un widget que se salió de la grilla.

### 12.1 Dos paletas que no se mezclan

| Paleta | Qué viste | Dónde vive |
|---|---|---|
| **Marca** — verde, azul, ámbar | El chrome: cabecera, barra inferior, botones, la llama de la racha | `AppColors` |
| **Metas** — los 8 slots | La identidad de cada meta: espina de la tarjeta, badge del icono, relleno del check | `HabitPalette` |

Están separadas a propósito. Si fueran una sola, la app no podría distinguir "esto es un botón" de
"esta es la meta de meditar". El dueño decidió el 2026-08-17 que **el color lo elige el usuario**
(los 8 slots), no la categoría — el `DESIGN.md` proponía derivarlo de la categoría, pero eso dejaba
siete categorías sin color y mataba `HabitColorSlot`.

Los 8 slots se **revalidaron** contra las superficies nuevas y siguen pasando; ver la tabla en
`HabitPalette`. El modo oscuro se derivó de los tokens `inverse-*` y `*-fixed-dim` que el propio
documento trae, no se inventó.

### 12.2 El icono sale de la categoría

`CategoryIcons` mapea las 10 categorías a glifos. Sin campo nuevo en `Habit` y sin selector en el
formulario. El precio es que es tosco: una meta llamada "Tomar agua" archivada en Salud recibe un
corazón, no una gota. Si eso molesta, un `icon` nullable en `Habit` que sobreescriba el mapa es un
cambio aditivo.

### 12.3 El estado que el diseño no tenía

Ninguna captura muestra un check deshabilitado, y esa es una regla central de la app (§3.5). Se
resolvió así, y está pendiente de que el dueño lo apruebe o lo reemplace por un frame propio:

- **Hoy no toca** → caja con borde tenue, no tocable, y el renglón de la racha dice "Hoy no toca".
- **Cupo lleno** → igual, con "3/3 esta semana".
- **Completada hoy** → caja rellena con el color de la meta, nombre tachado, y **sigue siendo
  tocable** para deshacer. Bloquear el deshacer dejaría al usuario sin forma de corregir un toque
  accidental.

El renglón bajo el nombre describe el **horario**, y distingue los dos modos porque no son lo mismo:
`TimesPerPeriod` da "3 veces por semana", `SpecificWeekdays` da "Lun, Mié, Sáb". Confundirlos haría
que la tarjeta mienta sobre a qué se comprometió el usuario.

### 12.4 Alcance

- **El heatmap por tarjeta es fase 5**, por decisión del dueño. La tarjeta de la fase 3 llega hasta
  el renglón de estado.
- **La barra inferior de 4 pestañas se construyó en la fase 3** aunque solo la primera tenga
  contenido. Cambia la geometría de todas las pantallas —padding inferior, safe areas, dónde cabe un
  botón flotante— y meterla después obligaría a re-maquetar trabajo ya cerrado.
- **Crear una meta se hace desde un botón flotante `+` en la Home.** Decidido por el dueño el
  2026-08-17: el `DESIGN.md` no tenía ninguna entrada al formulario y las cuatro pestañas están
  ocupadas. Implementado en la fase 4; **tocar una tarjeta** abre esa misma pantalla en modo
  edición.
- **No hay fecha en la cabecera.** Estaba en las capturas; el dueño la quitó el 2026-08-17.
- **El saludo no lleva nombre.** El diseño dice "Good morning, Alex" pero la cuenta es anónima hasta
  la fase 7. Un saludo con un hueco donde va el nombre es peor que uno sin nombre.
