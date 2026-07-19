#!/usr/bin/env bash
set -euo pipefail
# Install .NET SDK (default: 8.0 via Ubuntu apt package dotnet-sdk-8.0).
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
ensure_prerequisites
run_playbook dotnet "$@"
