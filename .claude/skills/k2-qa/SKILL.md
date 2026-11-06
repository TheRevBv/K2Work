---
name: k2-qa
description: Fase QA de un ticket K2 - genera una matriz de casos de prueba en docs/tareas/<rama>/matriz-qa.md y la va llenando con resultados y evidencias. Usar cuando hay un fix listo para probar o el usuario pide matriz de pruebas, casos de prueba o reporta un resultado.
---

# Matriz QA

Va entre el fix y el PR: `k2-ticket` → `k2-rastrear` → fix → **`k2-qa`** (+ `k2-bd`) → PR.

## Generar

Archivo `docs/tareas/<rama>/matriz-qa.md`. Derivar casos de: requerimiento, cadena rastreada y reglas de negocio. Incluir siempre caso feliz, bordes (nulos, vacíos, duplicados), el flujo hermano y regresión.

    | # | Caso | Pasos / SQL | Esperado | Resultado | Evidencia |
    |---|------|-------------|----------|-----------|-----------|
    | 1 | ...  | datos/<ticket>/02-prueba.sql | ... | pendiente | |

## Llenar

- Resultado: `ok`, `falla` o `pendiente`. Una falla genera nota en Hallazgos de `docs/tareas/<rama>.md`.
- Evidencia: salida `.txt` de `bin/k2-sql` o captura numerada en la carpeta del ticket.
- Pruebas de backend: `run-tests-backend.sh <ruta>` desde la raíz del repo K2.

## Cierre

No dar el ticket por listo con casos `pendiente` o `falla`; listarlos al usuario.
