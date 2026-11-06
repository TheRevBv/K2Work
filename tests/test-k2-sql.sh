#!/usr/bin/env bash
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
K2="$ROOT/bin/k2-sql"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/cfg" "$TMP/cfg-prodname"
cat > "$TMP/mysql" <<'EOF'
#!/usr/bin/env bash
cat >> "$STUB_LOG"
printf '\n---\n' >> "$STUB_LOG"
[ -n "${STUB_OUT:-}" ] && printf '%s\n' "$STUB_OUT"
exit 0
EOF
chmod +x "$TMP/mysql"

profile() {
  printf 'K2_DB_HOST=127.0.0.1\nK2_DB_PORT=%s\nK2_DB_USER=u\nK2_DB_PASSWORD=secreto-xyz\nK2_DB_NAME=%s\n' "$2" "$3" > "$1"
}
profile "$TMP/cfg/db.local.env" 3306 k2_local
profile "$TMP/cfg/db.dev.env" 59999 k2_dev
profile "$TMP/cfg-prodname/db.local.env" 3306 k2_prod

export K2_CONFIG_DIR="$TMP/cfg" K2_MYSQL_BIN="$TMP/mysql" STUB_LOG="$TMP/log"
fail=0
ok()  { printf 'ok   %s\n' "$1"; }
bad() { printf 'FAIL %s\n' "$1"; fail=1; }

run() { # desc esperado_exit cmd...
  local d="$1" want="$2"; shift 2
  : > "$STUB_LOG"
  "$@" > "$TMP/out" 2> "$TMP/err"
  local got=$?
  if [ "$got" = "$want" ]; then ok "$d"; else bad "$d (exit $got, esperado $want)"; fi
}
log_has()  { grep -q -- "$2" "$STUB_LOG" && ok "$1" || bad "$1 (falta '$2' en la entrada a mysql)"; }
log_lacks(){ grep -q -- "$2" "$STUB_LOG" && bad "$1 (aparece '$2')" || ok "$1"; }
log_empty(){ [ ! -s "$STUB_LOG" ] && ok "$1" || bad "$1 (mysql fue invocado)"; }

run "perfil prod bloqueado" 2 "$K2" prod -e "SELECT 1"
log_empty "prod no invoca mysql"
run "perfil test bloqueado" 2 "$K2" test -e "SELECT 1"
run "nombre de base con prod bloqueado" 2 env K2_CONFIG_DIR="$TMP/cfg-prodname" "$K2" local -e "SELECT 1"
log_empty "base prod no invoca mysql"

run "select se ejecuta" 0 "$K2" local -e "SELECT 1"
log_has "select llega a mysql" "SELECT 1;"
log_lacks "select sin rollback" "ROLLBACK"

run "update va con rollback" 0 "$K2" local -e "UPDATE t SET a=1"
log_has "update abre transaccion" "START TRANSACTION"
log_has "update cierra con rollback" "ROLLBACK"

run "ddl sin commit rechazado" 5 "$K2" local -e "CREATE TABLE x (a int)"
log_empty "ddl rechazado no invoca mysql"
run "show create table permitido" 0 "$K2" local -e "SHOW CREATE TABLE x"

run "commit local persiste" 0 "$K2" local -e "UPDATE t SET a=1" --commit
log_lacks "commit sin rollback" "ROLLBACK"

run "dev sin proxy" 4 "$K2" dev -e "SELECT 1"
run "patron invalido" 1 "$K2" local tablas "x;drop"

run "buscar arma LIKE" 0 env STUB_OUT=nombre "$K2" local buscar "o'b" clientes
log_has "buscar usa LIKE" "LIKE '%o''b%'"

run "password no se imprime" 0 "$K2" local -e "SELECT 1"
if grep -q "secreto-xyz" "$TMP/out" "$TMP/err"; then bad "password filtrada en salida"; else ok "password no aparece en salida"; fi

cat > "$TMP/dump" <<'EOF'
#!/usr/bin/env bash
echo "args: $*"
echo "/*!50013 DEFINER=\`u\`@\`%\` SQL SECURITY DEFINER */"
echo "/*!50106 CREATE*/ /*!50117 DEFINER=\`u\`@\`%\`*/ /*!50106 EVENT e"
echo "CREATE DEFINER=\`u\`@\`%\` PROCEDURE p()"
exit "${STUB_DUMP_EXIT:-0}"
EOF
chmod +x "$TMP/dump"
export K2_DUMP_BIN="$TMP/dump"
run "dump genera archivo" 0 "$K2" local dump "$TMP/a.sql.gz" base_a base_b
gzip -dc "$TMP/a.sql.gz" | grep -q -- '--databases base_a base_b' && ok "dump pasa las bases" || bad "dump pasa las bases"
gzip -dc "$TMP/a.sql.gz" | grep -q 'DEFINER=`' && bad "dump conserva DEFINER" || ok "dump quita DEFINER"
run "dump no sobrescribe" 1 "$K2" local dump "$TMP/a.sql.gz" base_a
run "dump bloquea base prod" 2 "$K2" local dump "$TMP/b.sql.gz" k2_prod
STUB_DUMP_EXIT=3 run "dump propaga fallo" 3 "$K2" local dump "$TMP/c.sql.gz" base_a
[ ! -e "$TMP/c.sql.gz" ] && ok "dump fallido no deja archivo final" || bad "dump fallido no deja archivo final"

exit $fail
