#!/usr/bin/env bash
# SCA diferencial: compara advisories HIGH/CRITICAL (npm audit, solo runtime)
# entre el commit base y el commit actual. Solo las NUEVAS bloquean.
set -euo pipefail
sel='[.vulnerabilities[]?.via[]? | select(type=="object") | select(.severity=="high" or .severity=="critical") | "\(.severity)|\(.source)|\(.name)|\(.title)"] | unique | .[]'
audit() { # $1=directorio $2=salida
  ( cd "$1" && npm install --package-lock-only --omit=dev --ignore-scripts --no-audit --no-fund --legacy-peer-deps >/dev/null 2>&1 || true
    npm audit --omit=dev --json > "$2" 2>/dev/null || true )
}
audit . "$PWD/audit-head.json"
jq -r "$sel" audit-head.json | sort > head.txt
echo "Advisories HIGH/CRITICAL en HEAD: $(wc -l < head.txt)"
if [ -z "${BASE_SHA:-}" ]; then
  echo "::warning::Sin commit base: SCA en modo informe (${GATE_MODE_NOTE:-primer push})."
  cp head.txt new.txt
  echo "mode=report" >> "$GITHUB_OUTPUT"
else
  git worktree add -q ../base-tree "$BASE_SHA"
  audit ../base-tree "$PWD/audit-base.json"
  jq -r "$sel" audit-base.json | sort > base.txt
  comm -13 base.txt head.txt > new.txt
  echo "mode=diff" >> "$GITHUB_OUTPUT"
fi
new=$(wc -l < new.txt)
echo "new=${new}" >> "$GITHUB_OUTPUT"
echo "total=$(wc -l < head.txt)" >> "$GITHUB_OUTPUT"
{
  echo "### SCA (npm audit, runtime)"
  echo "- Advisories HIGH/CRITICAL totales (deuda heredada): $(wc -l < head.txt)"
  echo "- Advisories **nuevos** introducidos por este cambio: **${new}**"
  if [ "$new" -gt 0 ]; then echo; echo '| Severidad | Advisory | Paquete | Título |'; echo '|---|---|---|---|'; awk -F'|' '{printf "| %s | %s | %s | %s |\n",$1,$2,$3,$4}' new.txt; fi
} >> "$GITHUB_STEP_SUMMARY"
