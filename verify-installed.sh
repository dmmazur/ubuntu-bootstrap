#!/usr/bin/env bash
# Report what is installed vs expected (all sections from group_vars/all.yml).
#
# Usage:
#   ./verify-installed.sh
#   ./scripts/verify-common.sh   # one section
#
# Exit 1 if any expected item is MISSING (skipped/disabled sections do not fail).

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/verify-lib.sh
source "${SCRIPT_DIR}/scripts/verify-lib.sh"
verify_all
