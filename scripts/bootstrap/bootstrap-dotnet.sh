#!/usr/bin/env bash
set -euo pipefail
# Install .NET SDK (default: 8.0 via apt package dotnet-sdk-8.0).
# On Ubuntu 26.04+, adds ppa:dotnet/backports first (.NET 8 is not in the built-in feed).
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
ensure_prerequisites
run_playbook dotnet "$@"
