#!/usr/bin/env bash
# Uninstall .NET SDK package from the `dotnet` section.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_sudo

log "uninstall: dotnet"
pkg="$(yaml_scalar dotnet_sdk_package)"
[[ -z "${pkg}" ]] && pkg=dotnet-sdk-8.0
apt_purge "${pkg}"
log "done (dotnet)."
