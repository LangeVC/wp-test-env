#!/bin/bash
# Deprecated: Use scripts/setup.sh instead.
# This script is kept for backward compatibility.
# It delegates to scripts/setup.sh for full environment setup.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${SCRIPT_DIR}/scripts/setup.sh" "$@"
