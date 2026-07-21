#!/usr/bin/env bash
# Uninstall local .deb apps from the `debs` section (Cursor / VeraCrypt patterns).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_sudo

log "uninstall: debs"
# Package names match group_vars debs[].name when installed via apt from .deb
apt_purge veracrypt cursor
log "done (debs)."
