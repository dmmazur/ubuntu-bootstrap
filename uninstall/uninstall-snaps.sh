#!/usr/bin/env bash
# Remove snaps installed by the `snaps` section.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_sudo

log "uninstall: snaps"
mapfile -t names < <(yaml_list snaps)
for name in "${names[@]}"; do
  [[ -z "${name}" ]] && continue
  snap_remove "${name}"
done
log "done (snaps)."
