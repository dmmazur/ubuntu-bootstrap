#!/usr/bin/env bash
set -euo pipefail
# Install LaTeX Workshop into Cursor and/or VS Code (self-contained).
# Skips an editor if its CLI (code / cursor) is not on PATH.
#
# Usage:
#   ./scripts/bootstrap/bootstrap-latex-editors.sh
#
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
ensure_prerequisites
log "LaTeX editors (ansible --tags latex-editors)"
run_playbook latex-editors "$@"
