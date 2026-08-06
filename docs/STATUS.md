# Estado del proyecto

> Dónde está la construcción ahora mismo. **Se actualiza al cerrar cada fase**, en el mismo PR.
> El roadmap completo vive en `ARCHITECTURE.md` §10 — aquí no se duplica para que no se
> desincronice.

**Última actualización:** 2026-08-06
**Fase actual:** 1 — Dominio **completada**. Siguiente: fase 2 (infraestructura).
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

### Pruebas

96 en verde, `flutter analyze` limpio. `test/domain/`:

- `fixtures.dart` — constructores de metas y entradas; las fechas ancla son reales de 2026.
- Entidades: `date_only`, `date_period`, `habit_schedule`, `habit`.
- Servicios: `streak_calculator` (los dos ejemplos del propio `ARCHITECTURE.md` §4, cambio de año,
  semana ISO a caballo entre meses y entre años, rango cerrado, período abierto, mes fallado,
  racha que atraviesa un cambio de horario, subida y bajada de objetivo a mitad de semana),
  `habit_completion_policy`.
- `domain_purity_test.dart` — falla el build si alguien importa Flutter, Firebase, `dart:ui` o
  `dart:io` dentro de `lib/domain/`. La regla de dependencia deja de depender de la disciplina.

**Todavía no hay:** Firebase, implementaciones de los contratos, blocs ni UI real.

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
| Commits | Conventional, solo `feat`/`fix`/`docs`/`refactor`, y **cortos** |
| **Modelado del dominio** | **Clases Dart 3 a mano (`sealed`/`final`) + `equatable`, sin `freezed`.** Es lo que dibuja el propio §3.2, y deja `domain/` sin `build_runner` ni archivos generados. `freezed` se reserva para DTOs y estados de bloc |
| **Un período solo juzga si está completo** | Un bucket de modo B solo puede **cortar** la racha si está cerrado, entero dentro del rango y gobernado por un único modo. Si no, cuenta sus días pero no corta. Cubre la primera semana a medias y el cambio de modo a mitad de semana, y respeta que los buckets no se parten (§3.4) |
| **Ventana horaria** | Sin soporte para franjas que cruzan medianoche. No hace falta y volvería ambigua la pregunta "¿de qué día es esto?" |

---

## Qué sigue

**Fase 2 — Infraestructura.** Proyecto de Firebase (`flutterfire configure`), auth anónima,
datasources de Firestore, DTOs y mappers, `failure_mapper.dart`, y las implementaciones de los
tres repositorios. Los contratos ya están escritos y probados contra el dominio, así que esta fase
es rellenarlos.

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
- Proyecto de Firebase sin crear. Es lo primero de la fase 2.
- El bundle id sigue siendo el default `com.example.habit_tracker`. Cambiarlo antes de cualquier
  build de distribución.
- Quedan `.gitkeep` en `config/constants`, `config/di`, todo `infrastructure/` y
  `presentation/blocs` + `presentation/widgets/shared`; bórralos cuando la carpeta reciba su primer
  archivo real.
