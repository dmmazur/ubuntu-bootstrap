#!/usr/bin/env bash
# Uninstall experimental apt packages (kitty, tilix, …).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_sudo

log "uninstall: experimental"
mapfile -t pkgs < <(yaml_list apt_packages_experimental)
apt_purge "${pkgs[@]}"
log "done (experimental)."
