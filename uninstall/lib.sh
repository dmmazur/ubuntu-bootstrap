#!/usr/bin/env bash
# Shared helpers for ubuntu-bootstrap uninstall scripts.
#
# Usage from a section script:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
#   require_sudo
#   …

set -euo pipefail

UNINSTALL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${UNINSTALL_ROOT}"

# Reuse group_vars YAML parsers from verify-lib.
# shellcheck source=../scripts/verify/verify-lib.sh
source "${UNINSTALL_ROOT}/scripts/verify/verify-lib.sh"

export PATH="${HOME}/.local/bin:${PATH}"

log() { printf '==> %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

require_sudo() {
  if ! sudo -n true 2>/dev/null; then
    log "sudo password required (once for this run)"
    sudo -v
  fi
}

# Confirm destructive action unless UNINSTALL_YES=1.
confirm() {
  local prompt="${1:-Continue?}"
  if [[ "${UNINSTALL_YES:-}" == "1" ]]; then
    return 0
  fi
  local ans=""
  read -r -p "${prompt} [y/N] " ans || true
  case "${ans}" in
    y|Y|yes|YES) return 0 ;;
    *) log "Skipped."; return 1 ;;
  esac
}

apt_purge() {
  local -a pkgs=("$@")
  local -a present=()
  local p
  [[ ${#pkgs[@]} -eq 0 ]] && return 0
  for p in "${pkgs[@]}"; do
    [[ -z "${p}" ]] && continue
    if dpkg -s "${p}" &>/dev/null; then
      present+=("${p}")
    else
      log "apt: ${p} not installed (skip)"
    fi
  done
  if [[ ${#present[@]} -eq 0 ]]; then
    log "apt: nothing to purge"
    return 0
  fi
  log "apt purge: ${present[*]}"
  sudo env DEBIAN_FRONTEND=noninteractive apt-get purge -y "${present[@]}"
  sudo env DEBIAN_FRONTEND=noninteractive apt-get autoremove -y || true
}

rm_root_file() {
  local f="$1"
  if [[ -e "${f}" || -L "${f}" ]]; then
    log "remove ${f}"
    sudo rm -f "${f}"
  else
    log "missing ${f} (skip)"
  fi
}

rm_user_path() {
  local p="$1"
  if [[ -e "${p}" || -L "${p}" ]]; then
    log "remove ${p}"
    rm -rf "${p}"
  else
    log "missing ${p} (skip)"
  fi
}

# Remove lines matching extended regex from a file (user-owned).
sed_delete_lines() {
  local file="$1"
  local ere="$2"
  if [[ ! -f "${file}" ]]; then
    log "missing ${file} (skip sed)"
    return 0
  fi
  if grep -qE "${ere}" "${file}" 2>/dev/null; then
    log "edit ${file} (remove /${ere}/)"
    local tmp
    tmp="$(mktemp)"
    grep -vE "${ere}" "${file}" >"${tmp}" || true
    mv "${tmp}" "${file}"
  else
    log "no match in ${file} for /${ere}/ (skip)"
  fi
}

snap_remove() {
  local name="$1"
  if ! command -v snap >/dev/null 2>&1; then
    log "snap not available (skip ${name})"
    return 0
  fi
  if snap list "${name}" &>/dev/null; then
    log "snap remove ${name}"
    sudo snap remove "${name}" || warn "snap remove ${name} failed"
  else
    log "snap ${name} not installed (skip)"
  fi
}

flatpak_uninstall() {
  local app="$1"
  if ! command -v flatpak >/dev/null 2>&1; then
    log "flatpak not available (skip ${app})"
    return 0
  fi
  if flatpak info "${app}" &>/dev/null; then
    log "flatpak uninstall ${app}"
    flatpak uninstall -y "${app}" || warn "flatpak uninstall ${app} failed"
  else
    log "flatpak ${app} not installed (skip)"
  fi
}

run_as_login_user() {
  if [[ "$(id -u)" -eq 0 && -n "${SUDO_USER:-}" && "${SUDO_USER}" != root ]]; then
    runuser -u "${SUDO_USER}" -- "$@"
  else
    "$@"
  fi
}
