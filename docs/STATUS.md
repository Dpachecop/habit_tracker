# Estado del proyecto

> Dónde está la construcción ahora mismo. **Se actualiza al cerrar cada fase**, en el mismo PR.
> El roadmap completo vive en `ARCHITECTURE.md` §10 — aquí no se duplica para que no se
> desincronice.

**Última actualización:** 2026-08-06
**Fase actual:** 0 — Setup **completada**. Siguiente: fase 1 (dominio).
**Arquitectura:** aprobada por el dueño el 2026-08-06, con las correcciones ya incorporadas.

---

## Qué existe hoy

- `docs/ARCHITECTURE.md` — el diseño completo.
- `CLAUDE.md` — stack, invariantes y convenciones.
- Dependencias instaladas: `flutter_bloc`, `go_router`, `fpdart`, `freezed`, `fl_chart`, `uuid`,
  `intl`, `equatable`; en dev `build_runner`, `bloc_test`, `mocktail`.
- Estructura de las tres capas creada (carpetas vacías con `.gitkeep`).
- `config/theme` — `AppColors` (neutros del chrome) y `HabitPalette` (los 8 slots de color de
  meta, validados para daltonismo en claro y oscuro). `AppTheme` claro/oscuro.
- `domain/entities/habit_color_slot.dart` — único tipo de dominio que existe; lo necesitaba el
  tema. Su orden de declaración es la garantía de contraste, ver `ARCHITECTURE.md` §3.6.
- `config/router/app_router.dart` + `HomeScreen` placeholder, `main.dart` cableado.
- `test/app_boot_test.dart` — arranque y no-recreación del router.

`flutter analyze` limpio, tests en verde.

**Todavía no hay lógica de producto:** ni `Habit`, ni `HabitSchedule`, ni rachas, ni Firebase,
ni blocs.

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

---

## Qué sigue

**Fase 1 — Dominio.** Es la fase importante: entidades, `HabitSchedule`, `ScheduleVersion`,
la regla de marcado y el `StreakCalculator` con sus tests. Dart puro, sin UI ni Firebase.
Si el motor de rachas está bien y probado, el resto es pintar datos.

---

## Pendientes abiertos

- Proyecto de Firebase sin crear (`flutterfire configure`). Hace falta en la fase 2, no antes.
- El bundle id sigue siendo el default `com.example.habit_tracker`. Cambiarlo antes de cualquier
  build de distribución.
- Las carpetas de capa vacías se sostienen con `.gitkeep`; bórralos cuando la carpeta reciba
  su primer archivo real.
