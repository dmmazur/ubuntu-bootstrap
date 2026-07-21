#!/usr/bin/env bash
# Uninstall Claude Desktop and remove its apt repo + keyring.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_sudo

log "uninstall: claude"
apt_purge claude-desktop
rm_root_file "$(yaml_scalar claude_desktop_list)"
rm_root_file "$(yaml_scalar claude_desktop_keyring)"
sudo apt-get update -qq || warn "apt-get update reported errors (check other repos)"
log "done (claude)."
