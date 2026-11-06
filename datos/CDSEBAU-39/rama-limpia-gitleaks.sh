#!/usr/bin/env bash
# Crea una rama limpia (un solo commit squash sobre dev) a partir de la rama del PR #5
# para que Gitleaks no encuentre secretos en el historial.
# Uso (Git Bash en la VDI, dentro del clon de Micrositio-Autorelevo):
#   bash rama-limpia-gitleaks.sh [rama_origen] [rama_nueva]
set -euo pipefail

REMOTE=origin
BASE=dev
ORIGEN="${1:-CDSEBAU-39-autorelevo}"
NUEVA="${2:-CDSEBAU-39-autorelevo-clean}"
CACHE_DIR=.chubb-ui-mcp-cache
ARCHIVOS_SECRETOS=(
  autorelevo/src/environments/environment.ts
  autorelevo/src/environments/environment.prod.ts
  autorelevo/src/environments/environment.local.ts
  deploy/server.js
  CLAUDE.md
)
PATRON='password|passwd|pwd|api[-_]?key|apikey|secret|token'

confirmar() {
  read -r -p "$1 [s/N] " r
  [[ "$r" =~ ^[sS]$ ]]
}

echo "== 1. Verificando repo"
git rev-parse --is-inside-work-tree >/dev/null
if [[ -n "$(git status --porcelain)" ]]; then
  echo "Hay cambios sin commitear. Guárdalos (git stash) y vuelve a correr." >&2
  exit 1
fi
git fetch "$REMOTE" --prune
git rev-parse --verify -q "$REMOTE/$ORIGEN" >/dev/null || { echo "No existe $REMOTE/$ORIGEN" >&2; exit 1; }
git rev-parse --verify -q "$NUEVA" >/dev/null && { echo "La rama $NUEVA ya existe localmente" >&2; exit 1; }

echo "== 2. Creando $NUEVA desde $REMOTE/$BASE y aplicando $ORIGEN como squash"
git switch -c "$NUEVA" "$REMOTE/$BASE"
if ! git merge --squash "$REMOTE/$ORIGEN"; then
  echo "Hubo conflictos: resuélvelos, haz 'git add' y vuelve a correr desde el paso 3 a mano." >&2
  exit 1
fi

echo "== 3. Sacando $CACHE_DIR del repo e ignorándolo"
if git ls-files --error-unmatch "$CACHE_DIR" >/dev/null 2>&1; then
  git rm -r -q --cached "$CACHE_DIR"
fi
grep -qxF "$CACHE_DIR/" .gitignore 2>/dev/null || echo "$CACHE_DIR/" >> .gitignore
grep -qxF "autorelevo/src/environments/environment.local.ts" .gitignore \
  || echo "autorelevo/src/environments/environment.local.ts" >> .gitignore
if git ls-files --error-unmatch autorelevo/src/environments/environment.local.ts >/dev/null 2>&1; then
  git rm -q --cached autorelevo/src/environments/environment.local.ts
fi
git add .gitignore

echo "== 4. Líneas sospechosas en los archivos reportados"
for f in "${ARCHIVOS_SECRETOS[@]}"; do
  [[ -f "$f" ]] && git ls-files --error-unmatch "$f" >/dev/null 2>&1 || continue
  echo "--- $f"
  grep -nEi "$PATRON" "$f" || echo "(sin coincidencias)"
done
echo
echo "Edita esos archivos: deja los valores vacíos o como placeholder ('' / 'CHANGE_ME')"
echo "y en deploy/server.js léelos de process.env. Luego: git add <archivos>"
read -r -p "Presiona Enter cuando hayas editado y agregado los archivos..."

echo "== 5. Escaneo"
if command -v gitleaks >/dev/null 2>&1; then
  gitleaks protect --staged --redact -v || { echo "Gitleaks aún encuentra secretos. Corrige y vuelve a intentar." >&2; exit 1; }
else
  echo "gitleaks no está instalado; revisión con grep sobre lo staged:"
  git diff --cached -U0 | grep -nEi "^\+.*($PATRON)\s*[:=]\s*['\"][^'\"]{4,}" || echo "(sin coincidencias)"
fi

echo "== 6. Resumen de lo que entra"
git status --short | head -50
git diff --cached --stat | tail -1

if confirmar "¿Hacer el commit en $NUEVA?"; then
  git commit -m "CDSEBAU-39 autorelevo"
else
  echo "Sin commit. Los cambios quedan staged en $NUEVA."; exit 0
fi

if command -v gitleaks >/dev/null 2>&1; then
  gitleaks git --log-opts="$REMOTE/$BASE..HEAD" --redact -v || { echo "Gitleaks encontró algo en el commit; no se sube." >&2; exit 1; }
fi

if confirmar "¿Subir $NUEVA a $REMOTE?"; then
  git push -u "$REMOTE" "$NUEVA"
  echo "Listo. Abre el PR $NUEVA -> $BASE y cierra el PR #5."
fi
