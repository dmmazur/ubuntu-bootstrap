#!/usr/bin/env bash
# Uninstall common apt packages installed by the `common` section.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_sudo

log "uninstall: common"
mapfile -t pkgs < <(yaml_list apt_packages_common)
apt_purge "${pkgs[@]}"
log "done (common). Shared tools may still be pulled in by other sections."
