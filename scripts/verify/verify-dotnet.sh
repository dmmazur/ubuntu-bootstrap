#!/usr/bin/env bash
set -euo pipefail
# Checks .NET SDK install (apt package + dotnet CLI).
# shellcheck source=verify-lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/verify-lib.sh"
printf 'ubuntu-bootstrap install status — dotnet\n'
verify_dotnet
print_summary
