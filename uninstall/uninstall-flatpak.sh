#!/usr/bin/env bash
# Uninstall Flatpak apps installed by the `flatpak` section.
# Does not remove the Flathub remote (may be used by other apps).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

log "uninstall: flatpak"
mapfile -t apps < <(yaml_list flatpaks)
for app in "${apps[@]}"; do
  [[ -z "${app}" ]] && continue
  flatpak_uninstall "${app}"
done
log "done (flatpak). Flathub remote left in place."
