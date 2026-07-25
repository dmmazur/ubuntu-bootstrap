#!/usr/bin/env bash
# Uninstall .NET SDK package from the `dotnet` section.
# On Ubuntu 26.04+ also removes ppa:dotnet/backports if present.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_sudo

log "uninstall: dotnet"
pkg="$(yaml_scalar dotnet_sdk_package)"
[[ -z "${pkg}" ]] && pkg=dotnet-sdk-8.0
apt_purge "${pkg}"

ppa="$(yaml_scalar dotnet_backports_ppa)"
[[ -z "${ppa}" ]] && ppa="ppa:dotnet/backports"
if [[ -f /etc/os-release ]]; then
  # shellcheck source=/dev/null
  . /etc/os-release
fi
min_ver="$(yaml_scalar dotnet_backports_min_ubuntu)"
[[ -z "${min_ver}" ]] && min_ver="26.04"
if [[ "${ID:-}" == "ubuntu" ]] && dpkg --compare-versions "${VERSION_ID:-0}" ge "${min_ver}"; then
  if grep -rqE 'dotnet/backports|ppa\.launchpadcontent\.net/dotnet/backports' \
    /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null; then
    log "Removing ${ppa}"
    sudo add-apt-repository --remove -y "${ppa}" 2>/dev/null \
      || warn "Could not remove ${ppa} (remove manually if needed)"
    sudo apt-get update -qq 2>/dev/null || true
  fi
fi

log "done (dotnet)."
