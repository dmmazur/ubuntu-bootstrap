#!/usr/bin/env bash
set -euo pipefail
# Build + run LMTO UI (requires .NET SDK and ~/repos/lmto-ui).
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
ensure_prerequisites
run_playbook lmto-ui "$@"
