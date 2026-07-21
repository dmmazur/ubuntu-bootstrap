#!/usr/bin/env bash
# Run all section uninstall scripts (reverse of a typical full bootstrap).
# Asks once before starting unless UNINSTALL_YES=1.
#
# Order: lmto → latex-editors → latex → ollama → dotnet → chrome → claude →
#         debs → snaps → flatpak → lab → common
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${DIR}/lib.sh"

log "uninstall-all: revert ubuntu-bootstrap sections"
if ! confirm "Run ALL uninstall scripts? This removes packages and may delete ~/src / ~/R / ~/texmf after further prompts."; then
  exit 0
fi

export UNINSTALL_YES="${UNINSTALL_YES:-0}"

sections=(
  uninstall-lmto.sh
  uninstall-latex-editors.sh
  uninstall-latex.sh
  uninstall-ollama.sh
  uninstall-dotnet.sh
  uninstall-chrome.sh
  uninstall-claude.sh
  uninstall-debs.sh
  uninstall-snaps.sh
  uninstall-flatpak.sh
  uninstall-lab.sh
  uninstall-common.sh
)

# For lmto, prefer full cleanup when doing uninstall-all
for s in "${sections[@]}"; do
  log "---- ${s} ----"
  if [[ "${s}" == uninstall-lmto.sh ]]; then
    bash "${DIR}/${s}" all || warn "${s} exited non-zero"
  else
    bash "${DIR}/${s}" || warn "${s} exited non-zero"
  fi
done

log "uninstall-all finished."
