#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/main.sh
source "$SCRIPT_DIR/lib/main.sh"

main "$@"
