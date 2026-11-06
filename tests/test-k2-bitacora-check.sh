#!/usr/bin/env bash
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHK="$ROOT/bin/k2-bitacora-check"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fail=0
ok()  { printf 'ok   %s\n' "$1"; }
bad() { printf 'FAIL %s\n' "$1"; fail=1; }

cat > "$TMP/bien.md" <<'EOF'
1 de octubre
- Se atiende daily de canales
- Sin horas, formato antiguo

5 de octubre
- (3 h) [BAU] Se corrige el webhook
- (2 h) Se atiende weekly
- (3 h) Se revisan catalogos

6 de octubre
- (8 h) Se genera el CDM
EOF
"$CHK" "$TMP/bien.md" > "$TMP/out"; got=$?
[ "$got" = 0 ] && ok "dias correctos exit 0" || bad "dias correctos exit $got"
grep -q "^5 de octubre.*8.0.*ok" "$TMP/out" && ok "reporta 5 de octubre" || bad "no reporta 5 de octubre"
grep -q "^1 de octubre" "$TMP/out" && bad "dia sin horas no debe reportarse" || ok "ignora dia sin horas"

cat > "$TMP/mal.md" <<'EOF'
7 de octubre
- (3 h) Se revisa algo
- (2 h) Se atiende daily
EOF
"$CHK" "$TMP/mal.md" > "$TMP/out"; got=$?
[ "$got" = 1 ] && ok "suma incorrecta exit 1" || bad "suma incorrecta exit $got"
grep -q "DIFERENTE" "$TMP/out" && ok "marca DIFERENTE" || bad "no marca DIFERENTE"

exit $fail
