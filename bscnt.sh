#!/usr/bin/env bash
# Short alias for ./bootstrap-scientific.sh
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/bootstrap-scientific.sh" "$@"
