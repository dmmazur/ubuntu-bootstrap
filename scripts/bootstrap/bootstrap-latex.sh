#!/usr/bin/env bash
set -euo pipefail
# LaTeX / TeX Live install (self-contained; does not require lab/LMTO/common).
#
# Usage:
#   ./scripts/bootstrap/bootstrap-latex.sh              # all phases
#   ./scripts/bootstrap/bootstrap-latex.sh all
#   ./scripts/bootstrap/bootstrap-latex.sh apt          # 1) apt packages
#   ./scripts/bootstrap/bootstrap-latex.sh texmf        # 2) ~/texmf + optional userdata archive
#   ./scripts/bootstrap/bootstrap-latex.sh smoke        # 3) pdflatex smoke.tex
#
# Extra args after the phase are passed to ansible-playbook, e.g.:
#   ./scripts/bootstrap/bootstrap-latex.sh apt --check
#
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

phase="all"
if [[ $# -gt 0 ]]; then
  case "$1" in
    all|apt|texmf|smoke)
      phase="$1"
      shift
      ;;
  esac
fi

case "${phase}" in
  all)   tags="latex" ;;
  apt)   tags="latex-apt" ;;
  texmf) tags="latex-texmf" ;;
  smoke) tags="latex-smoke" ;;
esac

ensure_prerequisites
log "LaTeX phase: ${phase} (ansible --tags ${tags})"
run_playbook "${tags}" "$@"
