#!/usr/bin/env bash
set -euo pipefail
# LMTO phased install (AIR layout: LSYSTEM=ifx).
#
# Usage:
#   ./scripts/bootstrap-lmto.sh              # all phases
#   ./scripts/bootstrap-lmto.sh all
#   ./scripts/bootstrap-lmto.sh intel        # 1) Intel apt + bashrc
#   ./scripts/bootstrap-lmto.sh unpack       # 2) ~/src + unpack archives
#   ./scripts/bootstrap-lmto.sh build        # 3) configure + make
#   ./scripts/bootstrap-lmto.sh xscr         # 4) copy Xscr
#   ./scripts/bootstrap-lmto.sh ownership    # chown ~/src ~/bin ~/lib → login user
#
# Extra args after the phase are passed to ansible-playbook, e.g.:
#   ./scripts/bootstrap-lmto.sh intel --check
#
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

phase="all"
if [[ $# -gt 0 ]]; then
  case "$1" in
    all|intel|unpack|build|xscr|ownership)
      phase="$1"
      shift
      ;;
  esac
fi

case "${phase}" in
  all)       tags="lmto" ;;
  intel)     tags="lmto-intel" ;;
  unpack)    tags="lmto-unpack" ;;
  build)     tags="lmto-build" ;;
  xscr)      tags="lmto-xscr" ;;
  ownership) tags="lmto-ownership" ;;
esac

ensure_prerequisites
log "LMTO phase: ${phase} (ansible --tags ${tags})"
run_playbook "${tags}" "$@"
