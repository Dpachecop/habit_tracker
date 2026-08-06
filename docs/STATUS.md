# Estado del proyecto

> Dónde está la construcción ahora mismo. **Se actualiza al cerrar cada fase**, en el mismo PR.
> El roadmap completo vive en `ARCHITECTURE.md` §10 — aquí no se duplica para que no se
> desincronice.

**Última actualización:** 2026-08-06
**Fase actual:** 0 — Setup (sin empezar)
**Arquitectura:** aprobada por el dueño el 2026-08-06, con las correcciones ya incorporadas.

---

## Qué existe hoy

- Scaffold de Flutter sin tocar. `lib/main.dart` sigue siendo el "Hello World!" generado.
- `docs/ARCHITECTURE.md` — el diseño completo.
- `CLAUDE.md` — stack, invariantes y convenciones.
- Repo git con remoto en `github.com/Dpachecop/habit_tracker`, rama base `main`.

**Cero código de producto.** No hay dependencias añadidas, ni carpetas de capas, ni tests.

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

**Fase 0 — Setup.** Dependencias en `pubspec.yaml`, estructura de carpetas de las tres capas,
tema base con la paleta de colores seleccionables, `go_router` mínimo.

**Fase 1 — Dominio.** Es la fase importante: entidades, `HabitSchedule`, `ScheduleVersion`,
la regla de marcado y el `StreakCalculator` con sus tests. Dart puro, sin UI ni Firebase.
Si el motor de rachas está bien y probado, el resto es pintar datos.

---

## Pendientes abiertos

- Proyecto de Firebase sin crear (`flutterfire configure`). Hace falta en la fase 2, no antes.
- `gh` no está instalado, así que los PRs los abre el dueño desde la web. Las ramas se empujan
  y se le pasa el enlace.
- El bundle id sigue siendo el default `com.example.habit_tracker`. Cambiarlo antes de cualquier
  build de distribución.
