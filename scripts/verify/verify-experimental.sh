#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=verify-lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/verify-lib.sh"
printf 'ubuntu-bootstrap install status — experimental\n'
verify_experimental
print_summary
