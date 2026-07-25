#!/usr/bin/env bash
# First-time full workstation bootstrap after a fresh Ubuntu install.
#
# Usage (from a clone/copy of this repo):
#   ./bootstrap.sh
#   BOOTSTRAP_VERBOSE=1 ./bootstrap.sh
#
# Prerequisites:
#   - git clone https://github.com/dmmazur/ubuntu-bootstrap.git
#     (or copy the repo onto the machine)
#   - Optional: place Cursor/VeraCrypt .debs in files/
#   - Optional: copy/link LMTO source to ~/src before LMTO section runs
#
# Runs the complete playbook (all enabled sections in group_vars/all.yml).

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/bootstrap/lib.sh
source "${SCRIPT_DIR}/scripts/bootstrap/lib.sh"

log "ubuntu-bootstrap — full install"
ensure_prerequisites
run_playbook ""

log "Done."
