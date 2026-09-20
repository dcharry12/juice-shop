#!/usr/bin/env bash
# Resuelve el commit base contra el cual se comparan los hallazgos "nuevos".
# Salida: BASE_SHA=<sha> (vacío si no hay referencia válida, p. ej. primer push).
set -euo pipefail
base=""
if [ "${EVENT_NAME}" = "pull_request" ]; then
  base="${PR_BASE_SHA}"
elif [ "${EVENT_NAME}" = "push" ] && [ "${PUSH_BEFORE}" != "0000000000000000000000000000000000000000" ]; then
  base="${PUSH_BEFORE}"
fi
if [ -n "$base" ] && ! git cat-file -e "${base}^{commit}" 2>/dev/null; then base=""; fi
echo "BASE_SHA=${base}" >> "$GITHUB_ENV"
echo "Base de comparación: ${base:-<ninguna, modo informe>}"
