#!/usr/bin/env bash
set -euo pipefail
# Skipped when install_ollama: false in group_vars/all.yml
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
ensure_prerequisites
run_playbook ollama "$@"
