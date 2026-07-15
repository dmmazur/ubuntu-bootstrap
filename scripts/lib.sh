#!/usr/bin/env bash
# Shared helpers for ubuntu-bootstrap install scripts.

set -euo pipefail

# Repo root = parent of scripts/
BOOTSTRAP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${BOOTSTRAP_ROOT}"

export PATH="${HOME}/.local/bin:${PATH}"

log() { printf '==> %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

require_sudo() {
  if ! sudo -n true 2>/dev/null; then
    log "sudo password required (once for this run)"
    sudo -v
  fi
}

ensure_prerequisites() {
  require_sudo
  log "Installing Ansible and helper packages"
  sudo apt-get update -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ansible python3-pip gpg-agent wget curl git ca-certificates

  if ! ansible-galaxy collection list community.general &>/dev/null; then
    log "Installing Ansible collection: community.general"
    ansible-galaxy collection install community.general
  fi
}

run_playbook() {
  local tags="${1:-}"
  shift || true
  local extra_args=("$@")

  require_sudo
  [[ -f "${BOOTSTRAP_ROOT}/playbook.yml" ]] \
    || die "playbook.yml not found in ${BOOTSTRAP_ROOT}"

  local -a cmd=(
    sudo --preserve-env=HOME
    ansible-playbook "${BOOTSTRAP_ROOT}/playbook.yml"
    -e ansible_become=false
  )

  if [[ -n "${tags}" ]]; then
    cmd+=(--tags "${tags}")
  fi

  if [[ -n "${BOOTSTRAP_VERBOSE:-}" ]]; then
    cmd+=(-v)
  fi

  cmd+=("${extra_args[@]}")

  log "Running: ${cmd[*]}"
  "${cmd[@]}"
}
