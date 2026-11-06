#!/usr/bin/env bash
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GEN="$ROOT/bin/k2-bruno"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fail=0
ok()  { printf 'ok   %s\n' "$1"; }
bad() { printf 'FAIL %s\n' "$1"; fail=1; }

cat > "$TMP/spec.json" <<'JSON'
{
  "name": "Prueba",
  "host": "local",
  "env": "k2",
  "defaults": {"path": "/api/x", "body": {"a": 1, "t": {"b": "SI", "c": "x"}}},
  "requests": [
    {"name": "Base"},
    {"name": "Sin c", "merge": {"t": {"c": null}}},
    {"name": "Consulta", "method": "GET", "body": null, "folder": "Consultas"},
    {"name": "Subir", "body": null, "form": [{"name": "file", "file": "archivos/a.xlsx"}, {"name": "nota", "value": "x"}]}
  ]
}
JSON
"$GEN" "$TMP/spec.json" > /dev/null && ok "genera" || bad "no genera"
[ -f "$TMP/opencollection.yml" ] && ok "opencollection.yml" || bad "falta opencollection.yml"
[ -f "$TMP/1 Login K2.yml" ] && ok "agrega login" || bad "falta login"
grep -q '"c": "x"' "$TMP/2 Base.yml" && ok "body por defecto" || bad "body por defecto"
grep -q '"c"' "$TMP/3 Sin c.yml" && bad "merge null no borra" || ok "merge null borra llave"
grep -q "method: GET" "$TMP/Consultas/1 Consulta.yml" && ok "folder y metodo" || bad "folder y metodo"
grep -q "body:" "$TMP/Consultas/1 Consulta.yml" && bad "body null debe omitirse" || ok "sin body"
[ -L "$TMP/.env" ] && ok ".env es symlink" || bad ".env no es symlink"
grep -q 'process.env.K2_PASS' "$TMP/opencollection.yml" && ok "password por env" || bad "password por env"
grep -q "type: multipart-form" "$TMP/4 Subir.yml" && ok "form multipart" || bad "form multipart"
grep -q '"archivos/a.xlsx"' "$TMP/4 Subir.yml" && ok "form archivo" || bad "form archivo"
grep -q "application/json" "$TMP/4 Subir.yml" && bad "form no lleva json" || ok "form sin content-type json"
"$GEN" "$TMP/spec.json" > /dev/null 2>&1 && bad "sobrescribe sin --force" || ok "pide --force"
cat > "$TMP/spec2.json" <<'JSON'
{"name": "P2", "host": "local", "defaults": {"path": "/api/x", "body": null},
 "requests": [{"name": "Form", "form": [{"name": "file", "file": "a.xlsx"}]}]}
JSON
mkdir -p "$TMP/c2" && "$GEN" "$TMP/spec2.json" --out "$TMP/c2" > /dev/null
grep -q "type: json" "$TMP/c2/2 Form.yml" && bad "defaults body null no debe generar json" || ok "defaults body null"
exit $fail
