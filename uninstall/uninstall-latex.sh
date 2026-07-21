#!/usr/bin/env bash
# Uninstall TeX Live apt packages and optional latex userdata dirs from `latex`.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_sudo

log "uninstall: latex"
mapfile -t pkgs < <(yaml_list apt_packages_latex)
apt_purge "${pkgs[@]}"

texmf="$(yaml_scalar latex_texmf_dir)"
[[ -z "${texmf}" ]] && texmf="${HOME_DIR}/texmf"
smoke="$(yaml_scalar latex_smoke_dir)"
[[ -z "${smoke}" ]] && smoke="${HOME_DIR}/TeX/smoke"

if [[ -e "${texmf}" ]]; then
  if confirm "Remove LaTeX tree ${texmf}?"; then
    rm_user_path "${texmf}"
  fi
fi
if [[ -e "${smoke}" ]]; then
  if confirm "Remove smoke dir ${smoke}?"; then
    rm_user_path "${smoke}"
  fi
fi
log "done (latex)."
