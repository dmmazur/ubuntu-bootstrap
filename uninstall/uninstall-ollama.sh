#!/usr/bin/env bash
# Uninstall Ollama service/binary installed by the `ollama` section.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_sudo

log "uninstall: ollama"
if systemctl list-unit-files ollama.service &>/dev/null; then
  sudo systemctl stop ollama 2>/dev/null || true
  sudo systemctl disable ollama 2>/dev/null || true
fi
rm_root_file /etc/systemd/system/ollama.service
sudo systemctl daemon-reload 2>/dev/null || true
rm_root_file /usr/bin/ollama
# Upstream tarball may also place libs under /usr/lib/ollama
if [[ -d /usr/lib/ollama ]]; then
  log "remove /usr/lib/ollama"
  sudo rm -rf /usr/lib/ollama
fi
if id ollama &>/dev/null; then
  if confirm "Remove system user 'ollama' and /usr/share/ollama?"; then
    sudo userdel ollama 2>/dev/null || warn "userdel ollama failed"
    sudo rm -rf /usr/share/ollama
  fi
fi
log "done (ollama)."
