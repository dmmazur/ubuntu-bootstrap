#!/usr/bin/env bash
# Stop LMTO UI user service and remove unit (does not delete ~/repos/lmto-ui).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_sudo

log "uninstall: lmto-ui"
user="${SUDO_USER:-${USER}}"
home="$(getent passwd "${user}" | cut -d: -f6)"
[[ -z "${home}" ]] && home="${HOME}"
unit="${home}/.config/systemd/user/lmto-ui.service"
uid="$(id -u "${user}" 2>/dev/null || true)"
runtime="/run/user/${uid:-}"

if [[ -n "${uid}" && -d "${runtime}" ]]; then
  sudo -u "${user}" -H \
    env XDG_RUNTIME_DIR="${runtime}" DBUS_SESSION_BUS_ADDRESS="unix:path=${runtime}/bus" \
    systemctl --user disable --now lmto-ui 2>/dev/null || true
fi
if [[ -f "${unit}" ]]; then
  log "Removing ${unit}"
  rm -f "${unit}"
fi
log "done (lmto-ui). Repo left at ${home}/repos/lmto-ui if present."
