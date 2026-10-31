#!/usr/bin/env bash
# Compatibility entry point retained for existing menu references.
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$HERE/online-monitor.sh" "$@"
