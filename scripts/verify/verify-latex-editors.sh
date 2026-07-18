#!/usr/bin/env bash
set -euo pipefail
# Checks LaTeX Workshop extension in VS Code and/or Cursor.
# shellcheck source=verify-lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/verify-lib.sh"
printf 'ubuntu-bootstrap install status — latex-editors\n'
verify_latex_editors
print_summary
