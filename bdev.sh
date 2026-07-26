#!/usr/bin/env bash
# Short alias for ./bootstrap-development.sh
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/bootstrap-development.sh" "$@"
