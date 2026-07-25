#!/usr/bin/env bash
# Scientific stack: common → lab → lmto → latex → dotnet
#
# Usage:
#   ./bootstrap-scientific.sh
#   BOOTSTRAP_VERBOSE=1 ./bootstrap-scientific.sh
#
# See also: ./bootstrap-development.sh  ./bootstrap.sh (everything)

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/bootstrap/lib.sh
source "${SCRIPT_DIR}/scripts/bootstrap/lib.sh"

log "ubuntu-bootstrap — scientific (common, lab, lmto, latex, dotnet)"
ensure_prerequisites
run_playbook "common,lab,lmto,latex,dotnet" "$@"

log "Done. Open a new shell if Intel/LMTO env vars were added."
