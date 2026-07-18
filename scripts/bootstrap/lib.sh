#!/usr/bin/env bash
# Shared helpers for ubuntu-bootstrap install scripts.

set -euo pipefail

# Repo root = parent of scripts/ (this file lives in scripts/bootstrap/)
BOOTSTRAP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${BOOTSTRAP_ROOT}"

export PATH="${HOME}/.local/bin:${PATH}"

log() { printf '==> %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

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
  # tee makes stdout a pipe (not a TTY); force Ansible/Python colors anyway.
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

ensure_prerequisites() {
  require_sudo
  setup_bootstrap_logs
  log "Installing Ansible and helper packages"
  run_logged apt-prereqs-update \
    sudo apt-get update -qq
  run_logged apt-prereqs-install \
    sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y \
      ansible python3-pip gpg-agent wget curl git ca-certificates

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

  require_sudo
  setup_bootstrap_logs
  [[ -f "${BOOTSTRAP_ROOT}/playbook.yml" ]] \
    || die "playbook.yml not found in ${BOOTSTRAP_ROOT}"

  local -a cmd=(
    sudo --preserve-env=HOME,BOOTSTRAP_LOG_DIR,ANSIBLE_LOG_PATH,ANSIBLE_FORCE_COLOR,PY_COLORS,TERM
    env ANSIBLE_FORCE_COLOR="${ANSIBLE_FORCE_COLOR}" PY_COLORS="${PY_COLORS}"
    ansible-playbook "${BOOTSTRAP_ROOT}/playbook.yml"
    -e ansible_become=false
    -e "bootstrap_log_dir=${BOOTSTRAP_LOG_DIR}"
  )

  if [[ -n "${tags}" ]]; then
    cmd+=(--tags "${tags}")
  fi

  if [[ -n "${BOOTSTRAP_VERBOSE:-}" ]]; then
    cmd+=(-v)
  fi

  cmd+=("${extra_args[@]}")

  log "Running: ${cmd[*]}"
  set +e
  "${cmd[@]}" 2>&1 | tee -a "${BOOTSTRAP_LOG_DIR}/playbook.log"
  local rc=${PIPESTATUS[0]}
  set -e

  {
    printf '\n# finished %s  rc=%s\n' "$(date -Iseconds)" "${rc}"
    printf '# logs in %s\n' "${BOOTSTRAP_LOG_DIR}"
    ls -la "${BOOTSTRAP_LOG_DIR}"
  } | tee -a "${BOOTSTRAP_LOG_DIR}/playbook.log"

  log "Finished (rc=${rc}). Logs: ${BOOTSTRAP_LOG_DIR}"
  return "${rc}"
}
