#!/usr/bin/env bash
set -euo pipefail
# Checks LaTeX apt packages, pdflatex, kpsewhich, ~/texmf, smoke.pdf.
# shellcheck source=verify-lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/verify-lib.sh"
printf 'ubuntu-bootstrap install status — latex\n'
verify_latex
print_summary
