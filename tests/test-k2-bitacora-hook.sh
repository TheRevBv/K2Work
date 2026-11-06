#!/usr/bin/env bash
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$ROOT/bin/k2-bitacora-hook"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fail=0
ok()  { printf 'ok   %s\n' "$1"; }
bad() { printf 'FAIL %s\n' "$1"; fail=1; }

DIR="$TMP/Trabajo/Cds/Mensuales"
mkdir -p "$DIR"
printf '5 de octubre\n- (8.5 h) Se trabaja\n' > "$DIR/Tareas Octubre 2026.md"
export K2_VAULT="$TMP"

out="$(K2_TODAY=2026-10-12 "$HOOK")"
echo "$out" | grep -q "12 de octubre" && ok "avisa si falta el dia (lunes 12)" || bad "no avisa el dia faltante"

out="$(K2_TODAY=2026-10-05 "$HOOK")"
[ -z "$out" ] && ok "silencio si el dia existe" || bad "habla aunque existe el dia: $out"

out="$(K2_TODAY=2026-10-10 "$HOOK")"
[ -z "$out" ] && ok "silencio en sabado" || bad "habla en sabado: $out"

out="$(K2_TODAY=2026-11-02 "$HOOK")"
echo "$out" | grep -q "2 de noviembre" && ok "avisa si no existe el archivo del mes" || bad "no avisa mes sin archivo"

exit $fail
