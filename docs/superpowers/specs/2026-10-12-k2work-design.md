# K2Work — diseño del espacio de trabajo

Fecha: 2026-10-12 · Estado: aprobado por el usuario, pendiente de plan de implementación

## Objetivo

Crear `~/Código/personal/K2Work`, un espacio de apoyo análogo a `OPUSWork`, para trabajar con Claude Code en el proyecto K2 (CDS) y en el micrositio de autorelevo:

- agentes/skills y configuración de la forma de trabajo,
- documentación de tickets, módulos y contexto reutilizable,
- consultas y pruebas SQL rápidas contra MySQL,
- bitácora diaria de actividades en Obsidian.

K2Work es un workspace aparte: no se commitea nada suyo dentro de `K2-Full-Portal` ni de los repos del micrositio.

## Alcance y supuestos

| Tema | Decisión |
|---|---|
| Ubicación | `~/Código/personal/K2Work`, junto a `OPUSWork` y `SIFWork` |
| Código | `../K2-Full-Portal` (admin Angular + apiserver Flask) y `../micrositio-autorelevo` |
| Backend | Flask 3.1, Flask-Cors, flask-swagger, SQLAlchemy 2.0, MySQL vía `mysql+pymysql`, alembic en `apiserver/migrations`; despliegue App Engine |
| Git | repo local propio de K2Work, sin remoto; commits solo con permiso del usuario y sin atribución de Claude |
| Bitácora | `~/Documentos/ObsidianVault/Trabajo/Cds/Mensuales/Tareas <Mes> <Año>.md`, con horas, 8.5 h por día |
| Micrositio | proyecto dentro de K2Work (`docs/proyectos/micrositio-autorelevo/`) |
| Alcance CDS | cubre todo lo de CDS (K2, Blip, pólizas, canales), no solo autorelevo |

## Estructura

```
K2Work/
├── AGENTS.md                 reglas, stack, entorno, flujo (para cualquier agente)
├── CLAUDE.md                 @AGENTS.md + notas específicas de Claude Code (español)
├── README.md
├── docs/
│   ├── arquitectura.md       Angular admin → api.service.ts → Flask (ix/) → SQLAlchemy → MySQL
│   ├── modulos/              un archivo por módulo (asistencias, WA hogar/vial, catálogos…)
│   ├── tareas/               <rama>.md + carpeta de evidencias por ticket
│   ├── proyectos/micrositio-autorelevo/   contexto, decisiones, estado
│   └── superpowers/specs/    este documento
├── rag/                      glosario.md, indice-archivos.md
├── practicas/convenciones.md ramas, commits, estilo de código
├── skills/README.md          índice de skills (el código está en .claude/skills/)
├── datos/<ticket>/           01-diagnostico.sql, 02-prueba.sql, salidas .txt
└── .claude/
    ├── settings.local.json   permisos y hook SessionStart
    └── skills/k2-*/SKILL.md
```

## Skills

| Skill | Función |
|---|---|
| `k2-ticket` | documenta requerimiento, capturas y chats en `docs/tareas/<rama>.md` y su carpeta de evidencias |
| `k2-rastrear` | rastrea un flujo: componente Angular → `api.service.ts` → ruta Flask → servicio/repositorio → modelo → tabla |
| `k2-bd` | consultas y pruebas SQL (ver sección siguiente) |
| `k2-git` | ramas, commits sin atribución, corrección de commits; siempre pregunta antes de commitear o hacer push |
| `k2-qa` | matriz de casos en `docs/tareas/<rama>/matriz-qa.md`; enlaza cada caso a su script en `datos/` |
| `k2-autorelevo` | contexto y reglas del micrositio: UI Chubb, hash ids de documentos, token de prueba |
| `k2-bitacora` | llena la bitácora CDS (ver sección) |

Flujo de un ticket: `k2-ticket` → `k2-rastrear` → `k2-bd` (reproducir) → fix mínimo → `k2-git` → `k2-qa`.

## `k2-bd`: consultas y pruebas SQL

**Perfiles de conexión.** Cada perfil es un archivo `~/.config/k2work/db.<perfil>.env` (permisos 600, fuera del repo, creado por el usuario). K2Work nunca contiene credenciales y la skill nunca imprime sus valores.

| Perfil | Destino | Escritura |
|---|---|---|
| `local` | MySQL local | permitida |
| `dev` | MySQL de dev en GCP por proxy (Cloud SQL Auth Proxy → `127.0.0.1:<puerto>`) | permitida con rollback por defecto |
| `test`, `prod` | — | **bloqueados**: el wrapper rechaza el perfil, sin opción de override |

**Wrapper `k2-sql`.** Script en `K2Work/bin/k2-sql`:

- `k2-sql <perfil> -e "<consulta>"` o `k2-sql <perfil> -f archivo.sql`; salida en tabla.
- Antes de conectar valida que el perfil sea `local` o `dev`; cualquier otro nombre, o un host que coincida con test/prod, aborta.
- Para `dev`, verifica que el proxy escuche en el puerto configurado y avisa si no.
- Sentencias DML (`INSERT`/`UPDATE`/`DELETE`/`REPLACE`) se ejecutan envueltas en `START TRANSACTION … ROLLBACK`. El DDL (`ALTER`/`CREATE`/`DROP`/`TRUNCATE`…) hace commit implícito en MySQL y no puede revertirse, así que se rechaza salvo con `--commit`. Persistir requiere `--commit` y confirmación explícita del usuario en la conversación; en `dev` el wrapper además exige `K2_CONFIRM_DEV=si`, que solo se define tras esa confirmación.
- Atajos de búsqueda: `k2-sql <perfil> tablas <patrón>`, `columnas <patrón>` (busca una columna en todas las tablas), `describe <tabla>`, `buscar <valor>` (valor en columnas de texto/ids de las tablas indicadas).

**Evidencia.** Los scripts de un ticket viven en `datos/<ticket>/NN-descripcion.sql`; la salida relevante se guarda como `NN-descripcion.txt` junto al script y se referencia desde `docs/tareas/<rama>.md` y la matriz QA.

## `k2-bitacora`

- Archivo: `Trabajo/Cds/Mensuales/Tareas <Mes> <Año>.md`; si el mes no existe se crea.
- Formato (igual a `opus-bitacora`): encabezado `<día> de <mes>` en minúsculas, línea en blanco entre días, viñetas `- (N h) Se …` en impersonal, múltiplos de 0.5 h, **suma exacta de 8.5 h por día**, solo días hábiles.
- Fuentes: lo que dicte el usuario (dailies, weeklies, reuniones), `docs/tareas/*.md` con fecha, y commits propios del día en los repos de K2 y micrositio.
- No reescribe días ya llenos salvo petición.
- Al terminar muestra tabla día → horas e indica qué se dedujo sin evidencia para que el usuario lo confirme.
- Los días existentes sin horas (formato antiguo) se respetan; el formato con horas aplica a los días nuevos.

## Reglas para agentes (AGENTS.md)

1. Sin commits, push ni PRs sin confirmación explícita; nunca `Co-Authored-By` ni `Claude-Session`.
2. Sin comentarios narrativos de IA en el código (`FIX C1: antes…`); solo JSDoc/docstrings útiles.
3. Sin credenciales ni datos sensibles en K2Work; el token de prueba de la API se obtiene leyendo el `.env` del apiserver dentro de un script, sin imprimirlo.
4. No escribir en test/prod; no ejecutar SQL que persista sin confirmación.
5. Antes de proponer un fix, rastrear el flujo completo con `k2-rastrear`.
6. Documentar hallazgos en `docs/tareas/<rama>.md` y lo reutilizable en `rag/`.
7. Responder en español.

## Hook

`SessionStart` (en `.claude/settings.local.json`): mensaje breve que indica si la bitácora del día hábil anterior o actual no tiene entrada. Sin más hooks por ahora.

## Poblado inicial

1. Extraer convenciones reales (stack, comandos, correcciones recurrentes) de los transcripts de `~/.claude/projects/*K2*` y `*autorelevo*`; mostrarlas al usuario antes de fijarlas en `practicas/` y `rag/glosario.md`.
2. Mapear `apiserver/ix/` (api, ctrl, svc, repositories, models, whatsApp…) para `docs/arquitectura.md` e `indice-archivos.md`.
3. Sembrar `docs/proyectos/micrositio-autorelevo/` con `Autorelevo_Contexto_y_Prompt_Codex.md` y las memorias existentes.
4. No leer `.env` ni archivos de credenciales durante el poblado.

## Fuera de alcance

- Migraciones alembic (se hacen con las herramientas del repo, no con una skill de K2Work).
- Acceso a test/prod.
- Hooks adicionales y automatizaciones no pedidas.
