---
name: k2-bruno
description: Genera colecciones de Bruno 4.x (formato OpenCollection YAML, el de la versión instalada) para probar endpoints de K2 a partir de un spec JSON con bin/k2-bruno. Usar cuando el usuario pide "colección Bruno", "casos en Bruno", "requests para probar el endpoint" o actualizar una colección existente con un payload nuevo (ej. JSON que manda Blip/Telasist).
---

# Colecciones Bruno

Bruno instalado: `bruno-bin 4.2.1` → colecciones **OpenCollection YAML** (`opencollection.yml` + un `.yml` por request), no `.bru`.
Encaja en `k2-qa`: cada caso de la matriz es un request.

## Dónde viven

- Por ticket: `datos/<ticket>/bruno/` (junto a `verificar.sql`).
- Generales (Blip, Chubb SIT, Telasist): `bruno/<Colección>/`.
- Workspace de Bruno: `~/.config/bruno/default-workspace/workspace.yml` (lista `collections: - name/path`). Al crear una colección nueva agrégala ahí; Bruno debe estar cerrado o hay que reabrirla a mano.

## Credenciales

Nunca en K2Work. El `.env` de cada colección es symlink a `~/.config/k2work/bruno/<env>.env` (permisos 600) y se usan como `{{process.env.VAR}}`.
- `k2.env`: `K2_PASS` del usuario de K2 (login `/api/auth/token`).
- `chubb-sit.env`: `CHUBB_SIT_*`, `CHUBB_UAT_*`.
Si falta una variable, pídele al usuario que la agregue con `! echo 'VAR=...' >> ~/.config/k2work/bruno/<env>.env`; no la pidas en el chat.

## Flujo

1. Tomar el payload real (correo, `web_service_log_blip`, schema en `apiserver/ix/whatsApp/schemas/schemas.py`) como `defaults.body`.
2. Un request por caso de prueba, variando solo lo necesario con `merge`.
3. Escribir `spec.json` en la carpeta destino y correr `bin/k2-bruno <spec.json> [--force]`.
4. Validar: `uv run -q --with pyyaml python -c "import yaml,glob; [yaml.safe_load(open(f)) for f in glob.glob('<dir>/**/*.yml', recursive=True)]"`.
5. Registrar la colección en `docs/tareas/<rama>.md` y en la matriz QA.

Para cambiar la colección se edita `spec.json` y se regenera con `--force` (borra los `.yml` y los vuelve a escribir). No edites los `.yml` generados a mano.

## Spec

```json
{
  "name": "CDSPC-147 grúa programada WA",
  "host": "blip",                 // local | blip | dev | URL completa
  "env": "k2",                    // ~/.config/k2work/bruno/k2.env
  "login": true,                  // agrega "1 Login K2" y auth bearer {{k2_token}} en la colección
  "user": "joshua.morinsalazar@chubb.com",
  "variables": {"poliza": "39002312"},
  "docs": "Markdown de la colección",
  "defaults": {"method": "POST", "path": "/api/v2/wa/create_ticket", "body": {"PolizaId": "{{poliza}}", "ticket": {"programado": "SI"}}},
  "requests": [
    {"name": "Caso feliz", "docs": "Esperado: ..."},
    {"name": "Sin fecha", "merge": {"ticket": {"fechaYhora": null}}},
    {"name": "Otro endpoint", "method": "GET", "path": "/api/assistancecases/{{caseId}}", "body": null, "folder": "Consultas"},
    {"name": "Sin token", "auth": "none", "headers": {"X-Debug": "1"}, "tests": ["res.getStatus() === 401"],
     "vars": {"caseId": "67613"}, "script": "bru.setVar('caseId', res.getBody().data);"}
  ]
}
```

- `merge`: merge profundo sobre `defaults.body`; `null` borra la llave. `body` en el request lo reemplaza completo (`null` = sin body).
- `tests`: expresiones JS que deben ser `true`; por omisión `res.getStatus() === 200`.
- `folder`: crea subcarpeta con `folder.yml`. Los archivos se numeran por carpeta según el orden.
- Hosts: `local` = `http://127.0.0.1:8080`, `blip` = versión App Engine `blip` en dev, `dev` = `https://dev.k2web.online`. Nunca test/prod.

Ejemplo completo: `datos/cdspc-147/bruno/spec.json`.
