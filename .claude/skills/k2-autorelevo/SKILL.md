---
name: k2-autorelevo
description: Contexto y reglas para trabajar en el micrositio de autorelevo de K2 (siniestros). Usar cuando se toque micrositio-autorelevo o su integración con la API de K2.
---

# Micrositio de autorelevo

Repo de trabajo: `../micrositio-autorelevo-real`. Contexto del proyecto: `docs/proyectos/micrositio-autorelevo/` (incluye `Autorelevo_Contexto_y_Prompt_Codex.md`).

## Repos y ramas

- Trabajar siempre en `../micrositio-autorelevo-real` (también visible como `~/github/personal/micrositio-autorelevo-real`; `~/github` es un symlink a `~/Código`) y cambiar de contexto con ramas: `git switch <rama>`.
- No crear carpetas ni worktrees nuevos, salvo que el usuario lo pida.
- Las ramas `fix/CDSEBAU-39-restaurar-merge`, `infra/local`, `infra/local-v2` e `infra/local-vdi` son historia no relacionada con la v2: se consultan o se toman commits con `cherry-pick`, no se fusionan.
- `deploy/` y `@chubb/ui-components` solo existen en el repo corporativo de la VDI: desde aquí no se compila ni se despliega la v2.

## Reglas

- Los componentes siguen la UI de Chubb; no introducir estilos propios sin pedirlo.
- Los documentos por subir se identifican por hash id; revisar su generación y consumo al tocar la carga de documentos.
- El código se integra al repo corporativo: sin comentarios narrativos de IA, solo JSDoc/docstrings útiles.
- Preguntar antes de commitear (skill `k2-git`).

## Probar contra la API local

Backend local en `127.0.0.1:8080`. El token de prueba se obtiene con un script que lee `K2_USER_ADMIN_TEST` y `K2_USER_ADMIN_TEST_PASSWORD` del `.env` del apiserver y hace `POST /api/auth/token` con `{"email","password"}`; luego `Authorization: Bearer <token>`. Leer el `.env` solo dentro del script; nunca imprimir los valores.

## Al cerrar una sesión

Actualizar `docs/proyectos/micrositio-autorelevo/estado.md` con lo hecho, decisiones y pendientes.
