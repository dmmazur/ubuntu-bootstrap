#!/usr/bin/env bash
# Uninstall lab apt packages installed by the `lab` section.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_sudo

log "uninstall: lab"
mapfile -t pkgs < <(yaml_list apt_packages_lab)
apt_purge "${pkgs[@]}"
log "done (lab)."
