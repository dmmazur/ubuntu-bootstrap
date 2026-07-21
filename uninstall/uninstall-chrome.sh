#!/usr/bin/env bash
# Uninstall Google Chrome and remove its apt repo + keyring.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_sudo

log "uninstall: chrome"
apt_purge google-chrome-stable
rm_root_file "$(yaml_scalar chrome_list)"
rm_root_file "$(yaml_scalar chrome_keyring)"
# Google sometimes also drops google-chrome.list via the package; clean leftovers.
rm_root_file /etc/apt/sources.list.d/google-chrome.list
sudo apt-get update -qq || warn "apt-get update reported errors (check other repos)"
log "done (chrome)."
