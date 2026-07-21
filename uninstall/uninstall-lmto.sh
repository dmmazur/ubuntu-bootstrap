#!/usr/bin/env bash
# Uninstall / revert LMTO bootstrap changes.
#
# Usage:
#   ./uninstall/uninstall-lmto.sh              # intel + xscr + shell env (safe default)
#   ./uninstall/uninstall-lmto.sh all          # everything below (asks before deleting ~/src, ~/R, …)
#   ./uninstall/uninstall-lmto.sh intel
#   ./uninstall/uninstall-lmto.sh xscr
#   ./uninstall/uninstall-lmto.sh build-outputs  # ~/bin/$LSYSTEM + ~/lib/$LSYSTEM (+ wrappers caution)
#   ./uninstall/uninstall-lmto.sh src          # delete ~/src (confirm)
#   ./uninstall/uninstall-lmto.sh rdir         # delete ~/R (confirm)
#   ./uninstall/uninstall-lmto.sh apt-deps     # purge apt_packages_lmto
#
# Env: UNINSTALL_YES=1 skips confirms.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_sudo

phase="${1:-default}"

lsystem="$(yaml_scalar lmto_lsystem)"
[[ -z "${lsystem}" ]] && lsystem=ifx
src_dir="${HOME_DIR}/src"
r_dir="${HOME_DIR}/R"
profile_script="$(yaml_scalar lmto_profile_script)"
[[ -z "${profile_script}" ]] && profile_script=/etc/profile.d/lmto.sh
intel_list="$(yaml_scalar intel_oneapi_list)"
intel_keyring="$(yaml_scalar intel_oneapi_keyring)"
fort_pkg="$(yaml_scalar lmto_intel_fortran_package)"
mkl_pkg="$(yaml_scalar lmto_intel_mkl_package)"
[[ -z "${fort_pkg}" ]] && fort_pkg=intel-oneapi-compiler-fortran
[[ -z "${mkl_pkg}" ]] && mkl_pkg=intel-oneapi-mkl

uninstall_intel() {
  log "lmto: intel — purge packages + repo + shell hooks"
  apt_purge "${fort_pkg}" "${mkl_pkg}"
  # Meta packages may leave versioned oneAPI packages; optional deep clean:
  if confirm "Also purge other installed intel-oneapi-* packages (large)?"; then
    mapfile -t extra < <(dpkg -l 'intel-oneapi-*' 2>/dev/null | awk '/^ii/{print $2}')
    if [[ ${#extra[@]} -gt 0 ]]; then
      apt_purge "${extra[@]}"
    fi
  fi
  rm_root_file "${intel_list}"
  rm_root_file "${intel_keyring}"
  rm_root_file "${profile_script}"
  sed_delete_lines "${HOME_DIR}/.bashrc" '^\s*export\s+LSYSTEM='
  sed_delete_lines "${HOME_DIR}/.bashrc" '^\s*(source|\.)\s+.*/setvars\.sh'
  sed_delete_lines "${HOME_DIR}/.profile" '^\s*(source|\.)\s+.*/setvars\.sh'
  sudo apt-get update -qq || warn "apt-get update reported errors"
}

uninstall_xscr() {
  log "lmto: xscr — remove SCRIPT binaries from ~/bin and SYSBIN"
  mapfile -t bins < <(yaml_list lmto_xscr_binaries)
  if [[ ${#bins[@]} -eq 0 ]]; then
    bins=(Xscr grf2eps grfonts)
  fi
  local b
  for b in "${bins[@]}"; do
    rm_user_path "${HOME_DIR}/bin/${b}"
    rm_user_path "${HOME_DIR}/bin/${lsystem}/${b}"
  done
}

uninstall_build_outputs() {
  log "lmto: build-outputs — ~/bin/${lsystem} and ~/lib/${lsystem}"
  if confirm "Remove ${HOME_DIR}/bin/${lsystem} and ${HOME_DIR}/lib/${lsystem}?"; then
    rm_user_path "${HOME_DIR}/bin/${lsystem}"
    rm_user_path "${HOME_DIR}/lib/${lsystem}"
    rm_user_path "${HOME_DIR}/lib/LMHELP"
  fi
  # Common SCRIPT wrappers installed by make into ~/bin (best-effort)
  local w
  for w in lmt orx orxs lmhelp; do
    if [[ -e "${HOME_DIR}/bin/${w}" ]]; then
      if confirm "Remove wrapper ${HOME_DIR}/bin/${w}?"; then
        rm_user_path "${HOME_DIR}/bin/${w}"
      fi
    fi
  done
}

uninstall_src() {
  if [[ ! -e "${src_dir}" ]]; then
    log "missing ${src_dir} (skip)"
    return 0
  fi
  if confirm "DELETE LMTO source tree ${src_dir}? This cannot be undone."; then
    rm_user_path "${src_dir}"
  fi
}

uninstall_rdir() {
  if [[ ! -e "${r_dir}" ]]; then
    log "missing ${r_dir} (skip)"
    return 0
  fi
  if confirm "DELETE LMTO cases dir ${r_dir}?"; then
    rm_user_path "${r_dir}"
  fi
}

uninstall_apt_deps() {
  log "lmto: apt-deps"
  mapfile -t pkgs < <(yaml_list apt_packages_lmto)
  apt_purge "${pkgs[@]}"
}

uninstall_nfs_symlinks() {
  # Best-effort: remove known symlink dests if they are symlinks
  local dest
  for dest in "${HOME_DIR}/dep24" "${HOME_DIR}/R_dep24" "${HOME_DIR}/TeX_dep24"; do
    if [[ -L "${dest}" ]]; then
      rm_user_path "${dest}"
    fi
  done
}

case "${phase}" in
  default|"")
    uninstall_xscr
    uninstall_intel
    ;;
  intel) uninstall_intel ;;
  xscr) uninstall_xscr ;;
  build-outputs) uninstall_build_outputs ;;
  src) uninstall_src ;;
  rdir) uninstall_rdir ;;
  apt-deps) uninstall_apt_deps ;;
  nfs-links) uninstall_nfs_symlinks ;;
  all)
    uninstall_xscr
    uninstall_build_outputs
    uninstall_intel
    uninstall_apt_deps
    uninstall_nfs_symlinks
    uninstall_rdir
    uninstall_src
    ;;
  *)
    die "unknown phase '${phase}' (default|all|intel|xscr|build-outputs|src|rdir|apt-deps|nfs-links)"
    ;;
esac

log "done (lmto ${phase})."
