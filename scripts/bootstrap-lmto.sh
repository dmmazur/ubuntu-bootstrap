#!/usr/bin/env bash
set -euo pipefail
# LMTO: Intel apt + env + build from ~/src (see files/LMTO.md)
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
ensure_prerequisites
run_playbook lmto "$@"
