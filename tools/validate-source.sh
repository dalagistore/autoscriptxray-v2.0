#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
command -v bash >/dev/null
bad=0
while IFS= read -r -d '' f; do
  if ! bash -n "$f"; then printf '[FAIL] Bash syntax: %s\n' "$f"; bad=1; fi
done < <(find "$ROOT" -type f -name '*.sh' -print0)
if command -v jq >/dev/null 2>&1; then
  while IFS= read -r -d '' f; do
    if ! jq empty "$f" >/dev/null; then printf '[FAIL] JSON syntax: %s\n' "$f"; bad=1; fi
  done < <(find "$ROOT/config" -type f -name '*.json' -print0)
else
  echo '[WARN] jq not installed; JSON checks skipped.'
fi
(( bad == 0 )) || exit 1
echo '[OK] Static syntax checks passed. This is not an end-to-end protocol test.'
