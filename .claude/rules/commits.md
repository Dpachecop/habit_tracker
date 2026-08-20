# Reglas de Desarrollo y Flujo de Trabajo

## 1. Convenciones de Commits (Conventional Commits)
Al final de cada ciclo de iteración, todos los commits deben seguir estrictamente el formato de Conventional Commits. 

**Tipos de commit permitidos:**
Solo se pueden utilizar los siguientes prefijos:
*   `feat`: Para el desarrollo de una nueva característica (feature).
*   `fix`: Para la corrección de errores (bugs).
*   `docs`: Para cambios exclusivos en la documentación.
*   `refactor`: Para cambios en el código que no corrigen errores ni añaden nuevas características.

**Formato esperado:**
`<tipo>: <descripción breve y clara del cambio>`
*(Ejemplo: `feat: agregar sistema de autenticación de usuarios`)*

## 2. Estrategia de Ramas (Branching)
*   **Nuevas características:** Para cada nueva *feature*, es obligatorio crear una nueva rama independiente a partir de la rama principal. 
*   **Nomenclatura recomendada:** `feat/nombre-de-la-caracteristica`.

## 3. Integración de Código
*   **Pull Requests (PRs):** Está prohibido integrar código directamente a la rama principal. Toda rama de una nueva característica debe integrarse exclusivamente a través de un Pull Request (PR) para asegurar la revisión del código antes del *merge*.