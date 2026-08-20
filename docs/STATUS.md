# Estado del proyecto

> Dónde está la construcción ahora mismo. **Se actualiza al cerrar cada fase**, en el mismo PR.
> El roadmap completo vive en `ARCHITECTURE.md` §10 — aquí no se duplica para que no se
> desincronice.

**Última actualización:** 2026-08-17
**Fase actual:** 5 — Cuadrícula de días **completada**, verificada en emulador Android.
Siguiente: fase 6 (reportes).
**Arquitectura:** aprobada por el dueño el 2026-08-06, con las correcciones ya incorporadas.

---

## Qué existe hoy

### De la fase 0

- `docs/ARCHITECTURE.md` — el diseño completo. `CLAUDE.md` — stack, invariantes y convenciones.
- Dependencias instaladas: `flutter_bloc`, `go_router`, `fpdart`, `freezed`, `fl_chart`, `uuid`,
  `intl`, `equatable`; en dev `build_runner`, `bloc_test`, `mocktail`.
- `config/theme` — `AppColors`, `HabitPalette` (8 slots validados para daltonismo en claro y
  oscuro), `AppTheme`.
- `config/router/app_router.dart` + `HomeScreen` placeholder, `main.dart` cableado.

### De la fase 1 — el dominio completo, Dart puro

`lib/domain/entities/`

| Archivo | Qué es |
|---|---|
| `date_only.dart` | Día de calendario sin hora ni zona. Toda la aritmética de rachas pasa por aquí |
| `weekday.dart` | Enum ISO, lunes = 1 |
| `date_period.dart` | Un bucket concreto: semana ISO / mes / año, con ambos extremos inclusive |
| `habit_schedule.dart` | La unión sellada `SpecificWeekdays` \| `TimesPerPeriod` + `SchedulePeriod` |
| `schedule_version.dart` | Horario + `effectiveFrom` |
| `date_range.dart` | Inicio y fin opcional |
| `time_window.dart` | Franja del día en minutos desde medianoche; `null` = todo el día |
| `habit_category.dart` | Enum cerrado de 10 categorías |
| `habit.dart` | La meta. `scheduleOn`, `targetForPeriod`, `appendScheduleVersion` |
| `habit_entry.dart` | Un check-in. Id de documento determinista |
| `streak.dart` | Resultado: `current`, `longest`, `lastCompletedDate` |
| `habit_color_slot.dart` | Ya existía; lo necesitaba el tema |

`lib/domain/services/`

- `streak_calculator.dart` — el motor. Una sola pasada hacia atrás que devuelve racha actual y
  máxima a la vez. Modo A consume un día por paso, modo B un período entero.
- `habit_completion_policy.dart` — la regla de §3.5. Devuelve un `CompletionAvailability` con el
  motivo y los contadores (`1/3 esta semana`) para la UI, y un `Either` para que el repositorio
  rechace la escritura.

`lib/domain/failures/failure.dart` — la unión sellada de `Failure` y `FailureCodes` con todos los
códigos en un solo sitio.

`lib/domain/repositories/` y `lib/domain/datasources/` — los contratos abstractos
(`HabitsRepository`, `EntriesRepository`, `AuthRepository`, `HabitsDatasource`,
`EntriesDatasource`). Los datasources lanzan; los repositorios traducen a `Either<Failure, T>`.

### Módulo de idiomas — español e inglés

Pedido por el dueño el 2026-08-06, fuera del roadmap original. Diseño en `ARCHITECTURE.md` §11.

- `lib/l10n/app_en.arb` (plantilla) y `app_es.arb`; `lib/l10n/generated/` versionado en git para
  que un clon nuevo analice sin tener que generar antes.
- `lib/config/l10n/app_locales.dart` — los dos idiomas y los delegates. El orden es `[es, en]`
  a propósito: es el fallback cuando el dispositivo no habla ninguno.
- `lib/presentation/l10n/` — `context.l10n`, `FailureCode → frase` (la otra mitad de §5) y
  `HabitCategory → etiqueta` + `"2/3 esta semana"`.
- `main.dart` y `HomeScreen` ya no tienen ni un string suelto.
- `test/presentation/l10n/translations_test.dart` rompe el build si una clave falta en un `.arb`,
  si un código de fallo o una categoría se queda sin frase propia, o si se declara un idioma sin
  traducciones.

El idioma sigue al del dispositivo; el selector manual llega con la pantalla de ajustes.

### De la fase 2 — infraestructura

`lib/infrastructure/models/` — `HabitDto` y `HabitEntryDto`: la forma del documento, separada de la
entidad. Las fechas se guardan como `yyyy-MM-dd`, no como timestamps: son días de calendario, y un
timestamp reintroduciría por la base de datos la zona horaria que `DateOnly` existe para quitar.
De paso ordenan lexicográficamente igual que cronológicamente, que es lo que hace posibles las
consultas por rango.

`lib/infrastructure/mappers/` — DTO ↔ entidad. Lo interesante es el horario: un documento no puede
guardar una unión sellada, así que cada versión lleva un discriminador `type` y se lee con un
switch que **falla ruidosamente** ante un tipo desconocido. Una categoría desconocida, en cambio,
degrada a `other`: es una etiqueta, no puede corromper una racha, y perder la meta entera por ella
sería mucho peor.

`lib/infrastructure/datasources/` — `FirestoreHabitsDatasource` y `FirestoreEntriesDatasource`.
Reciben el uid como **callback**, no como valor: la sesión cambia (anónima hoy, cuenta real en la
fase 7) y un uid capturado seguiría escribiendo en el árbol del usuario anterior. Las rutas se
construyen en `firestore_paths.dart`, un único sitio que tiene que coincidir con las reglas.

`lib/infrastructure/errors/` — `failure_mapper.dart` (el único archivo de la app al que se le
permite nombrar `FirebaseException`) y `guard.dart`, que envuelve las llamadas en `Either`. El
guard de streams usa un transformer y no `handleError` a propósito: `handleError` deja que el error
termine la suscripción, y la pantalla principal escucha `watchHabits` durante toda la vida de la
app — un fallo transitorio no puede dejarla muda para siempre.

`lib/infrastructure/repositories/` — los tres. `EntriesRepositoryImpl` es **el punto donde se
aplica §3.5**: antes de escribir consulta el período y le pregunta a `HabitCompletionPolicy`. Que
el botón esté deshabilitado es una cortesía; esto es la regla.

`lib/config/di/` — `AppDependencies` (raíz de composición, el único sitio que nombra a la vez un
datasource concreto y el contrato que cumple) y `AppBootstrap` (Firebase, caché offline, login
anónimo, y luego el grafo). `main.dart` ya inyecta los repositorios con `MultiRepositoryProvider`.

`firestore.rules` y `firestore.indexes.json` en la raíz, versionados. El índice `(habitId, date)`
no es opcional: sin él Firestore rechaza la consulta de los reportes.

### De la fase 3 — Home, con el sistema visual del dueño

El diseño **Serene Habit** entró en esta fase: `docs/design/DESIGN.md` + capturas. Decisiones en
`ARCHITECTURE.md` §12.

`lib/config/theme/` — `AppColors` (tokens del dueño, claros + oscuros derivados de sus propios
`inverse-*` y `*-fixed-dim`), `AppTypography` (la escala Inter mapeada a los slots de Material),
`AppDimens` (4px, radios, sombras), `CategoryIcons`. `HabitPalette` conserva los 8 slots y se
**revalidó** contra las superficies nuevas: pasan todos los gates.

Inter empaquetada en `assets/fonts/` (tres pesos estáticos, no la variable) con su licencia OFL.
Se empaqueta en vez de bajarse en runtime porque la app tiene que funcionar sin red.

`lib/presentation/blocs/habits/` — `HabitsBloc`. Dos suscripciones (metas y entradas) que se
recomponen juntas, el toggle optimista con reversión, y el contador de "te quedan N" derivado del
mismo veredicto del dominio que habilita el check, para que no puedan discrepar.

`lib/presentation/widgets/` — `HabitCard` y `HabitCheckBox`. La tarjeta solo pinta lo que el bloc le
entrega: nunca recalcula una racha ni decide si el check va habilitado.

`lib/presentation/screens/shell/` — la barra de 4 pestañas con `StatefulShellRoute`, Home real y
tres placeholders.

`lib/presentation/screens/home/debug_seed_button.dart` — andamio temporal, **ya borrado en la fase 4.**
Siembra tres metas que cubren todos los estados de tarjeta. Solo en debug (`kDebugMode`), fuera de
release. Existe porque la fase 3 dibuja tarjetas y la 4 es la única forma de crear una.

Nuevo en los contratos: `watchEntries({from, to})` — las entradas de **todas** las metas en una
ventana. Una suscripción para toda la Home en vez de una por meta.

### De la fase 4 — crear y editar metas

`lib/domain/services/schedule_change_policy.dart` — **dominio, no formulario**, porque son reglas de
negocio. Responde las dos preguntas de §3.4: desde cuándo aplica un horario nuevo (mañana para días
concretos, hoy para un objetivo por período) y si el cambio deja el período abierto inalcanzable.

`lib/presentation/blocs/habit_form/` — `HabitFormCubit`. Un Cubit y no un Bloc porque cada
interacción es "el usuario puso este campo en este valor". Guarda **las dos ramas** del horario a la
vez, así que alternar entre "días concretos" y "N veces" nunca pierde lo ya elegido.

`lib/presentation/screens/habit_form/` — la pantalla, una sola para crear y editar. Se diferencian
en tres sitios (título, aviso de vigencia, acción de archivar) y dos pantallas habrían duplicado
todos los campos para evitar duplicar esos tres.

El **botón `+`** en la Home abre el formulario; tocar una tarjeta lo abre en modo edición. La ruta
de edición **carga la meta por id** en vez de recibirla por `extra`: es un solo camino que también
funciona con un deep link, y con la caché offline resuelve en local.

**Archivar** vive al fondo del formulario, con la frase que explica que no es un borrado. Sin ella,
un botón rojo junto a la palabra "archivar" se lee como destructivo — y las metas nunca se borran
porque las entradas las referencian.

El **andamio de sembrado se borró**, como estaba previsto.

### De la fase 5 — la cuadrícula de días

`lib/domain/services/habit_day_status.dart` — **dominio**, porque "¿esto fue un fallo?" es una
pregunta de negocio. Tres estados y no dos: cumplido, fallado, y **no tocaba**. Un martes en una
meta de lunes/miércoles/sábado no es un fallo, y una meta de N veces por período no tiene días
fallados en absoluto. Detalle en `ARCHITECTURE.md` §12.6.

`lib/presentation/widgets/habit_heatmap.dart` — cuatro filas en orden de lectura, los últimos N días,
con la última celda en hoy. Cuántas columnas caben lo decide el widget por ancho disponible; el bloc
le pasa 240 días de estados y la tarjeta toma la cola que le entra.

La tarjeta se reestructuró: la espina de color pasó de un `Row` estirado a un `Stack`. `IntrinsicHeight`
**no puede contener un `LayoutBuilder`**, y el heatmap necesita uno para medir el ancho.

### Pruebas

271 en verde, `flutter analyze` limpio. `test/domain/`:

- `fixtures.dart` — constructores de metas y entradas; las fechas ancla son reales de 2026.
- Entidades: `date_only`, `date_period`, `habit_schedule`, `habit`.
- Servicios: `streak_calculator` (los dos ejemplos del propio `ARCHITECTURE.md` §4, cambio de año,
  semana ISO a caballo entre meses y entre años, rango cerrado, período abierto, mes fallado,
  racha que atraviesa un cambio de horario, subida y bajada de objetivo a mitad de semana),
  `habit_completion_policy`.
- `domain_purity_test.dart` — falla el build si alguien importa Flutter, Firebase, `dart:ui` o
  `dart:io` dentro de `lib/domain/`. La regla de dependencia deja de depender de la disciplina.

Y de la fase 2: mappers (ida y vuelta completa, historial multi-versión, documentos corruptos),
`failure_mapper`, rutas de Firestore, el guard de sesión cerrada, los tres repositorios sobre
datasources en memoria — incluyendo que una escritura rechazada por §3.5 **no escribe nada** — y
`FirebaseAuthRepository` sobre `firebase_auth_mocks`.

Y de la fase 3: `habits_bloc_test` (carga, las dos rachas, el toggle optimista y su reversión, el
contador), `habit_card_test` (los tres estados, ambos idiomas, modo oscuro, y **dentro de un
`ListView`** — ver abajo), `translations_test` ampliado.

Y de la fase 5: `habit_day_status_test` (los tres estados, el horario versionado, hoy y el futuro)
y `habit_heatmap_test` (columnas por ancho, la cola correcta, el relleno, los tres tonos, y que
hable como una sola etiqueta y no como setenta y seis).

Y de la fase 4: `schedule_change_policy_test` (las dos reglas de §3.4, incluido el ejemplo del
propio documento), `habit_form_cubit_test` (validación, creación, el append de versiones, la
advertencia y sus tres salidas, archivar) y `habit_form_screen_test`.

**Todavía no hay:** Analytics (fase 6), cuenta (fase 7).

---

## Decisiones cerradas

No volver a abrirlas sin que el dueño lo pida.

| Tema | Decisión |
|---|---|
| Arquitectura | Clean en 3 capas: `domain` / `infrastructure` / `presentation` |
| Estado | `flutter_bloc`, un bloc por contexto |
| Persistencia | Firestore con persistencia offline activada. Sin motor de sync propio |
| Auth | Anónima desde el primer arranque; cuenta real al final vía `linkWithCredential` |
| Use cases | No hay capa de use cases; la lógica vive en servicios de dominio |
| Rachas | Derivadas siempre, nunca en BD |
| Hoy / período abierto | Nunca cortan la racha |
| Sobrecumplir | Prohibido. Para hacer más días hay que editar la meta (§3.5) |
| Cambio de horario | Versionado con `effectiveFrom`; los períodos cerrados no se tocan (§3.4) |
| Objetivo de un período | El mayor `times` vigente durante ese período. Cubre subida y bajada (§3.4) |
| "Diaria" | Es `SpecificWeekdays` con los 7 días, no un modo aparte |
| Plataformas | android + ios. Web fuera de alcance |
| Commits | Conventional, solo `feat`/`fix`/`docs`/`refactor`, y **cortos**. La regla vive en `.claude/rules/commits.md` y se carga en cada sesión desde `CLAUDE.md` |
| **Idiomas** | **Español e inglés, con `.arb` + `gen_l10n`.** Ningún texto de usuario en el código. Plantilla en inglés (las claves son código), fallback en runtime en español (§11) |
| **`intl`** | Bajado a `^0.19.0`: es lo que fija `flutter_localizations` en Flutter 3.29.3. No se usaba en ningún sitio todavía |
| **Modelado del dominio** | **Clases Dart 3 a mano (`sealed`/`final`) + `equatable`, sin `freezed`.** Es lo que dibuja el propio §3.2, y deja `domain/` sin `build_runner` ni archivos generados. `freezed` se reserva para DTOs y estados de bloc |
| **Un período solo juzga si está completo** | Un bucket de modo B solo puede **cortar** la racha si está cerrado, entero dentro del rango y gobernado por un único modo. Si no, cuenta sus días pero no corta. Cubre la primera semana a medias y el cambio de modo a mitad de semana, y respeta que los buckets no se parten (§3.4) |
| **Ventana horaria** | Sin soporte para franjas que cruzan medianoche. No hace falta y volvería ambigua la pregunta "¿de qué día es esto?" |
| **Fechas en Firestore** | `yyyy-MM-dd` como string, no `Timestamp`. Son días de calendario; un timestamp devolvería la zona horaria que `DateOnly` quita. Además ordena y consulta por rango igual que una fecha |
| **Errores en streams** | Llegan como `Left` **sin terminar la suscripción**. `handleError` la mataría, y la Home escucha durante toda la vida de la app |
| **uid por callback** | Los datasources reciben `String? Function()`, no el uid. La sesión cambia en la fase 7 y un uid capturado escribiría en el árbol anterior |
| **`minSdk` = 23** | Subido desde el 21 de Flutter porque `firebase_auth` lo exige. API 23 es Android 6.0 (2015); el alcance perdido es despreciable |
| **Bundle id distinto por plataforma** | android `com.example.habit_tracker`, ios `com.example.habitTracker`. Apple no admite guion bajo — el primer intento de registrar la app iOS falló por eso. Al cambiarlo para distribuir, son **dos** strings |
| **Config de Firebase fuera del repo** | Los tres archivos generados van a `.gitignore` porque el repo es público. Por eso `AppBootstrap` inicializa **sin** `options`: importar `firebase_options.dart` rompería `analyze` y `test` en un clon nuevo |
| **Color de la meta** | Lo elige el usuario: los 8 `HabitColorSlot`. El `DESIGN.md` proponía derivarlo de la categoría, pero eso dejaba 7 categorías sin color y mataba el slot. Los 3 acentos del diseño pasan al chrome (§12.1) |
| **Icono de la meta** | Sale de la categoría, sin campo nuevo. Tosco a propósito: "Tomar agua" en Salud recibe un corazón, no una gota (§12.2) |
| **Modo oscuro** | Derivado por mí de los tokens `inverse-*` del propio diseño, no inventado. Pendiente de que el dueño lo revise |
| **Barra de 4 pestañas en la fase 3** | Aunque solo Home tenga contenido. Cambia la geometría de todas las pantallas; meterla después obligaría a re-maquetar (§12.4) |
| **Ventana de historial** | 400 días. Una racha más larga se lee truncada; el alternativo es bajar el historial completo para dibujar un número. `Streak.longest` de este bloc **no** sirve para Analytics |
| **Tope del objetivo por período** | 7 / 28 / 365. Un día solo se cumple una vez, así que el techo es la longitud del bucket; 28 y no 31 en el mes porque si no, febrero rompería la racha por culpa del calendario |
| **Vigencia acotada por abajo** | Si ya hay una versión pendiente para mañana, un cambio que propondría *hoy* se sube a esa fecha. Sin eso, `appendScheduleVersion` lanzaría; con eso, el último cambio gana y el pasado sigue intacto |
| **La edición carga por id** | No por `extra` de la ruta. Un solo camino que también sirve para deep links y rutas restauradas |
| **Cuadrícula de 4 filas** | Orden de lectura, no calendario. Elegida por el dueño sobre la de 7 filas estilo GitHub: más compacta y calca el Figma, a cambio de que una columna no signifique nada (§12.5) |
| **Un fallo se pinta gris** | No con el color de la meta desvaído. Un color lavado se lee como "a medias" y aquí nada está a medias |
| **`minSdk` iOS = 15.0** | Subido del 12.0 de la plantilla porque `cloud_firestore` lo exige. El espejo exacto del caso de Android |
| **Sin tests de Firestore real** | `fake_cloud_firestore` 4.1.1 no compila contra `cloud_firestore` 6.8, y la 4.2 exige Dart 3.8 (el proyecto está en 3.7.2). Ver *Pendientes* |

---

## Qué sigue

**Fase 6 — Reportes.** `ReportsBloc` y las gráficas de `fl_chart` en la pestaña Analytics, que hoy
es un placeholder. Ojo con una trampa ya anotada: `Streak.longest` que sale de `HabitsBloc` es solo
el máximo **dentro de la ventana de 400 días**, así que Analytics necesita su propia lectura más
ancha y no puede reutilizar ese número.

La pantalla de Analytics del diseño (`docs/design/screens/analytics_screen.png`) pide consistencia
general, racha más larga, total de cumplimientos y una gráfica por meta.

**Fase 3 — Home.** `HabitsBloc` alimentado por `watchHabits()`, `HabitCard` con la racha y el
check en el color de la meta, y el toggle optimista. Los repositorios ya están inyectados en el
árbol, así que el bloc solo tiene que pedirlos con `context.read`.

Antes de que la app arranque hace falta el paso manual de abajo.

---

## Pendientes abiertos

- **Las 10 categorías de `HabitCategory` son una propuesta, no una decisión del dueño.**
  `ARCHITECTURE.md` nombra el archivo pero nunca lista los valores. Están puestas como enum cerrado
  (health, fitness, mind, learning, work, finance, social, home, creativity, other) porque texto
  libre se fragmenta en "Gym"/"gym"/"GYM" en una semana. Cambiar la lista es un commit de una línea;
  pasar a categorías definidas por el usuario sí sería una entidad con id y nombre.
- **Aviso del formulario al subir un objetivo** (`ARCHITECTURE.md` §3.4, la nota de "efecto a
  vigilar"): pasar de 3 a 5 un sábado deja la semana inalcanzable y garantiza el corte. El dominio
  ya se comporta así — hay test —, falta que la fase 4 lo avise en pantalla.
- **Los datasources de Firestore no tienen tests propios.** `fake_cloud_firestore` 4.1.1 ya no
  compila contra `cloud_firestore` 6.8 (cambió la firma de `WriteBatch.update`) y la 4.2 pide Dart
  3.8, que Flutter 3.29.3 no trae. Lo que sí está cubierto: el mapeo entero (ida y vuelta), las
  rutas, el guard de sesión cerrada y todo el comportamiento de los repositorios sobre datasources
  en memoria. Lo que no: que las *queries* de Firestore devuelvan lo que se espera. Se recupera
  subiendo a Flutter ≥ 3.32 (Dart 3.8) y `fake_cloud_firestore` 4.2, o con un test de integración
  contra el emulador de Firestore. Subir Flutter es decisión del dueño, no la tomo yo.
- **Selector manual de idioma.** Hoy se sigue el del dispositivo. Va con la pantalla de ajustes,
  que es donde habrá dónde persistir la elección; un `LocaleCubit` sin UI sería código muerto.
- Proyecto de Firebase sin crear. Es lo primero de la fase 2.
- **El bundle id sigue siendo el default.** Cambiarlo antes de cualquier build de distribución, y
  recordar que son dos: `com.example.habit_tracker` en android y `com.example.habitTracker` en ios.
  Cambiarlo obliga a volver a registrar las apps en Firebase y a regenerar la configuración.
- **El estado deshabilitado del check es propuesta mía, no diseño del dueño.** Ninguna captura lo
  mostraba y es una regla central (§3.5). Está resuelto en §12.3 y funcionando; falta que el dueño
  lo apruebe o pase un frame propio.
- **App Check sin montar.** Es lo que evita que un tercero use tus credenciales de cliente para
  crear cuentas anónimas y gastar cuota. Las reglas ya impiden que lea datos ajenos; esto es cuota,
  no confidencialidad. Vale la pena antes de publicar.
- Quedan `.gitkeep` en `config/constants`, `presentation/blocs` y `presentation/widgets/shared`;
  bórralos cuando la carpeta reciba su primer archivo real.

---

## Firebase — estado real

Proyecto **`habit-tracker-f30b61`** (display name *Habit Tracker*), creado el 2026-08-07.
Consola: <https://console.firebase.google.com/project/habit-tracker-f30b61>

Hecho y verificado:

- Apps registradas: android `com.example.habit_tracker`, ios `com.example.habitTracker`.
- Base de datos Firestore `(default)` creada en `nam5`.
- Reglas e índices desplegados desde `firestore.rules` y `firestore.indexes.json`.
- Proveedor **Anonymous** habilitado en Authentication.

### Los archivos de configuración NO están en el repo

`lib/firebase_options.dart`, `android/app/google-services.json` y
`ios/Runner/GoogleService-Info.plist` están en `.gitignore`. El repo es público y, aunque esas
claves **no son secretos** — lo que protege los datos son las reglas, no la API key —, identifican
el proyecto y permitirían a un tercero crear cuentas anónimas y gastar cuota. Quien quiera cerrar
eso del todo, lo que hace falta es **App Check**, no esconder la key.

En una máquina nueva, después de clonar:

```bash
firebase login
flutterfire configure --project=habit-tracker-f30b61 \
  --platforms=android,ios \
  --android-package-name=com.example.habit_tracker \
  --ios-bundle-id=com.example.habitTracker --yes
```

`flutter analyze` y `flutter test` funcionan **sin** ese paso: `AppBootstrap` llama a
`Firebase.initializeApp()` sin `options` justo para no depender desde Dart de un archivo que no
está versionado. Solo un build sobre dispositivo necesita los archivos nativos.
