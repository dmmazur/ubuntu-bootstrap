#!/usr/bin/env bash
# Stop the LMTO UI user service (does not remove the unit or ~/repos/lmto-ui).
#
# Usage:
#   ./stop-lmto-ui.sh
#   ./stop-lmto-ui.sh --disable   # also disable autostart on login
#
# To remove the unit entirely: ./uninstall/uninstall-lmto-ui.sh

set -euo pipefail

disable=0
for arg in "$@"; do
  case "${arg}" in
    --disable|-d) disable=1 ;;
    -h|--help)
      sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
  esac
done

user="${SUDO_USER:-${USER}}"
uid="$(id -u "${user}" 2>/dev/null || id -u)"
runtime="${XDG_RUNTIME_DIR:-/run/user/${uid}}"

printf '==> stop lmto-ui (user=%s)\n' "${user}"

if [[ ! -d "${runtime}" ]]; then
  printf 'warning: %s missing — user systemd unavailable\n' "${runtime}" >&2
  printf 'If you started it with dotnet run, use Ctrl+C or:\n' >&2
  printf '  pkill -f "dotnet.*LmtoUi"\n' >&2
  exit 1
fi

run_user() {
  if [[ "$(id -u)" -eq 0 && -n "${SUDO_USER:-}" ]]; then
    sudo -u "${SUDO_USER}" -H \
      env XDG_RUNTIME_DIR="${runtime}" DBUS_SESSION_BUS_ADDRESS="unix:path=${runtime}/bus" \
      "$@"
  else
    env XDG_RUNTIME_DIR="${runtime}" DBUS_SESSION_BUS_ADDRESS="unix:path=${runtime}/bus" \
      "$@"
  fi
}

if [[ "${disable}" -eq 1 ]]; then
  run_user systemctl --user disable --now lmto-ui
  printf '==> lmto-ui stopped and disabled\n'
else
  run_user systemctl --user stop lmto-ui
  printf '==> lmto-ui stopped (still enabled; starts again on next login/boot if lingering)\n'
  printf '    To disable autostart: ./stop-lmto-ui.sh --disable\n'
fi

run_user systemctl --user --no-pager status lmto-ui || true
