#!/usr/bin/env bash
# Shared helpers for ubuntu-bootstrap install scripts.

set -euo pipefail

# Repo root = parent of scripts/ (this file lives in scripts/bootstrap/)
BOOTSTRAP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${BOOTSTRAP_ROOT}"

export PATH="${HOME}/.local/bin:${PATH}"

log() { printf '==> %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

is_wsl() {
  grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null \
    || grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null \
    || [[ -n "${WSL_DISTRO_NAME:-}" ]]
}

# Create /tmp/ubuntu-bootstrap.XXXXXX (or use BOOTSTRAP_LOG_DIR if set).
# Full console → playbook.log; Ansible detail → ansible.log; roles add per-command logs.
setup_bootstrap_logs() {
  if [[ -n "${BOOTSTRAP_LOG_DIR:-}" ]]; then
    mkdir -p "${BOOTSTRAP_LOG_DIR}"
  else
    BOOTSTRAP_LOG_DIR="$(mktemp -d /tmp/ubuntu-bootstrap.XXXXXX)"
  fi
  export BOOTSTRAP_LOG_DIR
  export ANSIBLE_LOG_PATH="${BOOTSTRAP_LOG_DIR}/ansible.log"
  # Playbook runs on a real TTY (see run_playbook); keep colors enabled anyway.
  export ANSIBLE_FORCE_COLOR="${ANSIBLE_FORCE_COLOR:-true}"
  export PY_COLORS="${PY_COLORS:-1}"
  # Keep a stable pointer to the latest run (overwritten each bootstrap).
  ln -sfn "${BOOTSTRAP_LOG_DIR}" /tmp/ubuntu-bootstrap-latest
  if [[ ! -f "${BOOTSTRAP_LOG_DIR}/.announced" ]]; then
    log "Command logs → ${BOOTSTRAP_LOG_DIR}"
    log "  (symlink /tmp/ubuntu-bootstrap-latest)"
    : >"${BOOTSTRAP_LOG_DIR}/.announced"
  fi
}

# Run a command, tee stdout+stderr to a named log under BOOTSTRAP_LOG_DIR.
# Usage: run_logged NAME command [args...]
run_logged() {
  local name="$1"
  shift
  setup_bootstrap_logs
  local logf="${BOOTSTRAP_LOG_DIR}/${name}.log"
  {
    printf '# %s  %s\n' "$(date -Iseconds)" "$*"
  } | tee -a "${logf}" >/dev/null
  set +e
  "$@" 2>&1 | tee -a "${logf}"
  local rc=${PIPESTATUS[0]}
  set -e
  return "${rc}"
}

require_sudo() {
  if ! sudo -n true 2>/dev/null; then
    log "sudo password required (once for this run)"
    sudo -v
  fi
}

# Prefer IPv4 for apt — WSL often has broken IPv6 routes to Ubuntu mirrors.
ensure_apt_force_ipv4() {
  local conf=/etc/apt/apt.conf.d/99ubuntu-bootstrap-force-ipv4
  if [[ "${BOOTSTRAP_FORCE_IPV4:-1}" != "1" ]]; then
    return 0
  fi
  if [[ ! -f "${conf}" ]] || ! grep -q 'ForceIPv4' "${conf}" 2>/dev/null; then
    log "Enabling apt Acquire::ForceIPv4 (${conf})"
    printf 'Acquire::ForceIPv4 "true";\n' | sudo tee "${conf}" >/dev/null
  fi
}

# Remove half-configured Intel oneAPI apt source that breaks every apt-get update.
repair_poisoned_intel_repo() {
  local list=/etc/apt/sources.list.d/oneAPI.list
  local keyring=/usr/share/keyrings/oneapi-archive-keyring.gpg
  local out=""
  out="$(sudo apt-get update -qq 2>&1 || true)"
  if echo "${out}" | grep -qE 'apt\.repos\.intel\.com.*(NO_PUBKEY|not signed)'; then
    warn "Intel oneAPI apt source is present but unsigned/missing key — removing to unblock apt"
    warn "See troubleshooting/intel-apt-repo-poisons-update.md"
    sudo rm -f "${list}" "${keyring}"
    return 0
  fi
  # Also drop empty keyring + list combo
  if [[ -f "${list}" ]] && { [[ ! -s "${keyring}" ]] || [[ ! -f "${keyring}" ]]; }; then
    warn "Intel oneAPI list exists without a usable keyring — removing"
    sudo rm -f "${list}" "${keyring}"
  fi
}

# openssh-server postinst often fails on WSL (systemctl); leave dpkg half-configured.
repair_broken_openssh_wsl() {
  is_wsl || return 0
  if dpkg -l openssh-server 2>/dev/null | grep -qE '^i[FU]'; then
    warn "openssh-server is half-configured (common on WSL) — removing to unblock apt"
    sudo env DEBIAN_FRONTEND=noninteractive dpkg --remove --force-remove-reinstreq openssh-server 2>/dev/null \
      || sudo env DEBIAN_FRONTEND=noninteractive apt-get -y -f install 2>/dev/null \
      || true
    sudo env DEBIAN_FRONTEND=noninteractive dpkg --configure -a 2>/dev/null || true
  fi
}

check_clock_skew() {
  # Advisory only — full detection needs apt (see ensure_prerequisites logs).
  if is_wsl; then
    warn "WSL tip: if apt says Release file is \"not valid yet\", sync time: sudo hwclock -s"
    warn "See troubleshooting/wsl-clock-skew-apt.md"
  fi
}

# Return 0 if host looks sinkholed (RFC1918 / link-local only).
dns_is_sinkholed() {
  local host="$1"
  local ips=""
  ips="$(getent ahosts "${host}" 2>/dev/null | awk '{print $1}' | sort -u | tr '\n' ' ')"
  [[ -z "${ips}" ]] && return 1
  local ip
  for ip in ${ips}; do
    case "${ip}" in
      10.*|192.168.*|172.1[6-9].*|172.2[0-9].*|172.3[0-1].*|127.*|0.0.0.0|::1|fe80:*)
        return 0
        ;;
    esac
  done
  return 1
}

check_vendor_dns() {
  local host=apt.repos.intel.com
  if dns_is_sinkholed "${host}"; then
    warn "DNS for ${host} looks sinkholed ($(getent ahosts "${host}" 2>/dev/null | awk '{print $1}' | head -3 | tr '\n' ' '))"
    warn "Intel oneAPI apt and some snaps will fail until WSL DNS is fixed."
    warn "See troubleshooting/wsl-dns-vendor-repos.md"
    export BOOTSTRAP_INTEL_DNS_BAD=1
  else
    export BOOTSTRAP_INTEL_DNS_BAD=0
  fi
}

bootstrap_preflight() {
  require_sudo
  setup_bootstrap_logs
  if is_wsl; then
    log "WSL detected — applying WSL-safe apt defaults (ForceIPv4; careful with snaps/ssh)"
    export BOOTSTRAP_IS_WSL=1
  else
    export BOOTSTRAP_IS_WSL=0
  fi
  ensure_apt_force_ipv4
  repair_poisoned_intel_repo
  repair_broken_openssh_wsl
  check_vendor_dns
  # Clock check is advisory (apt update noise); do not block unless STRICT.
  check_clock_skew || true
}

ensure_prerequisites() {
  bootstrap_preflight
  log "Installing Ansible and helper packages"
  set +e
  run_logged apt-prereqs-update \
    sudo apt-get update -qq
  local upd_rc=$?
  set -e
  if [[ ${upd_rc} -ne 0 ]]; then
    # Retry once after repairing common poison / openssh issues
    repair_poisoned_intel_repo
    repair_broken_openssh_wsl
    set +e
    run_logged apt-prereqs-update \
      sudo apt-get update -qq
    upd_rc=$?
    set -e
    if [[ ${upd_rc} -ne 0 ]]; then
      warn "apt-get update failed (rc=${upd_rc}). Continuing if packages are already present."
      warn "If you see 'not valid yet', fix the clock; if NO_PUBKEY, remove vendor lists."
    fi
  fi

  set +e
  run_logged apt-prereqs-install \
    sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
      ansible python3-pip gpg-agent wget curl git ca-certificates
  local ins_rc=$?
  set -e
  if [[ ${ins_rc} -ne 0 ]]; then
    repair_broken_openssh_wsl
    set +e
    run_logged apt-prereqs-install \
      sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
        ansible python3-pip gpg-agent wget curl git ca-certificates
    ins_rc=$?
    set -e
    [[ ${ins_rc} -eq 0 ]] || die "Failed to install Ansible prerequisites (rc=${ins_rc})"
  fi

  if ! ansible-galaxy collection list community.general &>/dev/null; then
    log "Installing Ansible collection: community.general"
    run_logged ansible-galaxy-community \
      ansible-galaxy collection install community.general
  fi
}

run_playbook() {
  local tags="${1:-}"
  shift || true
  local extra_args=("$@")

  bootstrap_preflight
  [[ -f "${BOOTSTRAP_ROOT}/playbook.yml" ]] \
    || die "playbook.yml not found in ${BOOTSTRAP_ROOT}"

  local wsl_e=false intel_dns_e=false
  [[ "${BOOTSTRAP_IS_WSL:-0}" == "1" ]] && wsl_e=true
  [[ "${BOOTSTRAP_INTEL_DNS_BAD:-0}" == "1" ]] && intel_dns_e=true

  local -a cmd=(
    sudo --preserve-env=HOME,BOOTSTRAP_LOG_DIR,ANSIBLE_LOG_PATH,ANSIBLE_FORCE_COLOR,PY_COLORS,TERM
    env ANSIBLE_FORCE_COLOR="${ANSIBLE_FORCE_COLOR}" PY_COLORS="${PY_COLORS}"
    ansible-playbook "${BOOTSTRAP_ROOT}/playbook.yml"
    -e ansible_become=false
    -e "bootstrap_log_dir=${BOOTSTRAP_LOG_DIR}"
    -e "bootstrap_is_wsl=${wsl_e}"
    -e "bootstrap_intel_dns_bad=${intel_dns_e}"
  )

  if [[ -n "${tags}" ]]; then
    cmd+=(--tags "${tags}")
  fi

  if [[ -n "${BOOTSTRAP_VERBOSE:-}" ]]; then
    cmd+=(-v)
  fi

  cmd+=("${extra_args[@]}")

  local playbook_log="${BOOTSTRAP_LOG_DIR}/playbook.log"
  {
    printf '# %s  %s\n' "$(date -Iseconds)" "${cmd[*]}"
    printf '# Note: ansible runs on a real TTY (not | tee) to avoid BrokenPipeError\n'
    printf '#       crash reports on Ubuntu 26 / Python 3.14. Detail → ansible.log\n'
  } >>"${playbook_log}"

  log "Running: ${cmd[*]}"
  # Do NOT pipe ansible-playbook through tee. On Ubuntu 26 (Python 3.14) that
  # often ends with: BrokenPipeError in locking_wrapper() and an Apport dialog
  # when the pipe closes (Ctrl+C, closed terminal, or normal cleanup).
  # Console output stays on the TTY; ANSIBLE_LOG_PATH has the full trace.
  set +e
  "${cmd[@]}"
  local rc=$?
  set -e

  {
    printf '\n# finished %s  rc=%s\n' "$(date -Iseconds)" "${rc}"
    printf '# ansible.log → %s\n' "${ANSIBLE_LOG_PATH}"
    printf '# logs in %s\n' "${BOOTSTRAP_LOG_DIR}"
    ls -la "${BOOTSTRAP_LOG_DIR}"
  } >>"${playbook_log}"

  log "Finished (rc=${rc}). Logs: ${BOOTSTRAP_LOG_DIR}"
  # Always print — needed even when the playbook fails mid-run (e.g. lmto-ui),
  # because common/lab/lmto often already installed PATH-dependent tools.
  suggest_activate_env
  return "${rc}"
}

# Child bootstrap processes cannot update the caller's shell. Point at a
# sourceable helper so PATH / Intel setvars / snap work without logout.
suggest_activate_env() {
  local act="${BOOTSTRAP_ROOT}/scripts/bootstrap/activate-env.sh"
  log "────────────────────────────────────────────────────────────"
  log "Refresh THIS terminal so ifx / lmt / orx / dotnet are on PATH:"
  log "  source ${act}"
  log "Or:  exec bash -l"
  log "(A child ./bootstrap*.sh cannot change your current shell env.)"
  log "────────────────────────────────────────────────────────────"
}
