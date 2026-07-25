#!/usr/bin/env bash
# Development / desktop stack:
#   snaps → claude → chrome → debs → latex-editors → flatpak → ollama → experimental
#
# Forces on sections that are off by default in group_vars (debs, flatpak,
# ollama, experimental). Override with extra -e flags if needed.
#
# Usage:
#   ./bootstrap-development.sh
#   BOOTSTRAP_VERBOSE=1 ./bootstrap-development.sh
#   # keep debs off for this run:
#   ./bootstrap-development.sh -e install_debs=false
#
# See also: ./bootstrap-scientific.sh  ./bootstrap.sh (everything)

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/bootstrap/lib.sh
source "${SCRIPT_DIR}/scripts/bootstrap/lib.sh"

log "ubuntu-bootstrap — development (snaps, claude, chrome, debs, latex-editors, flatpak, ollama, experimental)"
ensure_prerequisites
run_playbook \
  "snaps,claude,chrome,debs,latex-editors,flatpak,ollama,experimental" \
  -e install_debs=true \
  -e install_flatpak=true \
  -e install_ollama=true \
  -e install_experimental=true \
  "$@"

log "Done."
