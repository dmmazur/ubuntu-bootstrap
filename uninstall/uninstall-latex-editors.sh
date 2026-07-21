#!/usr/bin/env bash
# Uninstall LaTeX Workshop from VS Code / Cursor (`latex-editors` section).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

log "uninstall: latex-editors"
ext="$(yaml_scalar latex_workshop_extension_id)"
[[ -z "${ext}" ]] && ext=James-Yu.latex-workshop

mapfile -t editors < <(yaml_list latex_editors)
# yaml_list returns name fields for map lists
for cli in "${editors[@]}"; do
  [[ -z "${cli}" ]] && continue
  if ! command -v "${cli}" >/dev/null 2>&1; then
    log "${cli}: CLI missing (skip)"
    continue
  fi
  log "${cli} --uninstall-extension ${ext}"
  run_as_login_user "${cli}" --uninstall-extension "${ext}" \
    || warn "${cli}: uninstall-extension failed (may already be absent)"
done
log "done (latex-editors)."
