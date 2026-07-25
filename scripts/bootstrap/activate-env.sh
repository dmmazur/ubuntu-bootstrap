#!/usr/bin/env bash
# Refresh PATH / LMTO / Intel / snap in the *current* shell (no logout).
#
# Usage (must be sourced, not executed):
#   source ./scripts/bootstrap/activate-env.sh
#   . ~/repos/ubuntu-bootstrap/scripts/bootstrap/activate-env.sh
#
# Safe to run multiple times. Does not permanently change set -e/-u in your shell.

# If executed instead of sourced, print instructions and exit.
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
  printf 'error: source this file in your current shell:\n' >&2
  printf '  source %s\n' "$(cd "$(dirname "$0")" && pwd)/activate-env.sh" >&2
  exit 1
fi

_ub_activate_path_prepend() {
  local dir="$1"
  [[ -d "${dir}" ]] || return 0
  case ":${PATH}:" in
    *":${dir}:"*) ;;
    *) PATH="${dir}:${PATH}" ;;
  esac
}

# Snap CLI apps (code, etc.)
_ub_activate_path_prepend /snap/bin

# LMTO helpers (same idea as /etc/profile.d/lmto.sh)
export LSYSTEM="${LSYSTEM:-ifx}"
_ub_activate_path_prepend "${HOME}/bin"
_ub_activate_path_prepend "${HOME}/bin/${LSYSTEM}"

if [[ -f /etc/profile.d/lmto.sh ]]; then
  # shellcheck disable=SC1091
  . /etc/profile.d/lmto.sh
fi

# Intel oneAPI (matches ~/.bashrc line from lmto-intel)
_ub_setvars=""
_ub_had_e=0
_ub_had_u=0
case $- in *e*) _ub_had_e=1 ;; esac
case $- in *u*) _ub_had_u=1 ;; esac
for _ub_setvars in \
  /opt/intel/oneapi/setvars.sh \
  "${HOME}/intel/oneapi/setvars.sh"; do
  if [[ -f "${_ub_setvars}" ]]; then
    set +e
    set +u
    # shellcheck disable=SC1090
    . "${_ub_setvars}" >/dev/null 2>&1 || true
    break
  fi
done
((_ub_had_e)) && set -e
((_ub_had_u)) && set -u
unset _ub_setvars _ub_had_e _ub_had_u

export PATH

# Drop stale "command not found" hashes from before install
hash -r 2>/dev/null || true

printf 'ubuntu-bootstrap: environment refreshed (LSYSTEM=%s)\n' "${LSYSTEM}"
command -v ifx >/dev/null 2>&1 && printf '  ifx:    %s\n' "$(command -v ifx)"
command -v lmt >/dev/null 2>&1 && printf '  lmt:    %s\n' "$(command -v lmt)"
command -v orx >/dev/null 2>&1 && printf '  orx:    %s\n' "$(command -v orx)"
command -v dotnet >/dev/null 2>&1 && printf '  dotnet: %s\n' "$(command -v dotnet)"
command -v code >/dev/null 2>&1 && printf '  code:   %s\n' "$(command -v code)"
if systemctl --user is-active lmto-ui &>/dev/null; then
  printf '  lmto-ui: http://127.0.0.1:5100 (systemd --user)\n'
fi

unset -f _ub_activate_path_prepend
