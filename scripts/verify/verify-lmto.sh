#!/usr/bin/env bash
set -euo pipefail
# Checks Intel apt packages, ~/src, binaries, setvars, profile, scratch, home links, NFS.
# shellcheck source=verify-lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/verify-lib.sh"
printf 'ubuntu-bootstrap install status — lmto\n'
verify_lmto
print_summary
