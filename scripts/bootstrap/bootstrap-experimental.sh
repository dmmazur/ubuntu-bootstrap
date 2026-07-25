#!/usr/bin/env bash
set -euo pipefail
# Skipped when install_experimental: false in group_vars/all.yml
# Force: ./scripts/bootstrap/bootstrap-experimental.sh -e install_experimental=true
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
ensure_prerequisites
run_playbook experimental "$@"
