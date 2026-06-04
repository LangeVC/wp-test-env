#!/usr/bin/env bash
# =============================================================================
# wp-test-env — Port collision check (pre-flight)
# =============================================================================
# Fails fast if any port declared in the current .env (or passed as args) is
# already in use by another Docker container or another process on the host.
#
# Usage:
#   ./scripts/check-ports.sh                              # checks ports from .env
#   ./scripts/check-ports.sh 8082 3306 8083 1025 8025     # checks explicit ports
#   ./scripts/check-ports.sh --quiet                       # only print on failure
#
# Exit codes:
#   0  — all clear
#   1  — at least one port is occupied
#   2  — could not determine port state (lsof missing, etc.)
#
# Design intent: a project running this script with its own COMPOSE_PROJECT_NAME
# (a "kennung") must NOT collide with any other project's running stack. The
# user-visible signal is the project_name + the ports; collisions on either
# break the multi-instance promise.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

QUIET=false
if [ "${1:-}" = "--quiet" ]; then
    QUIET=true
    shift
fi

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { $QUIET || echo -e "${GREEN}[check-ports]${NC} $1"; }
warn() { $QUIET || echo -e "${YELLOW}[check-ports]${NC} $1"; }
err()  { echo -e "${RED}[check-ports]${NC} $1" >&2; }

# ── Collect ports to check ──────────────────────────────────────────────────
declare -a PORTS_TO_CHECK
declare -A PORT_LABELS  # port → human-readable label

if [ $# -gt 0 ]; then
    # Ports passed as args
    for p in "$@"; do
        PORTS_TO_CHECK+=("$p")
        PORT_LABELS[$p]="(arg)"
    done
else
    # Read from .env in repo root
    ENV_FILE="${ROOT_DIR}/.env"
    if [ ! -f "$ENV_FILE" ]; then
        err "no .env found at $ENV_FILE and no port args given"
        exit 2
    fi
    # shellcheck disable=SC1090
    set -a; source "$ENV_FILE"; set +a

    for var in WORDPRESS_PORT MYSQL_PORT PHPMYADMIN_PORT MAILHOG_SMTP_PORT MAILHOG_WEB_PORT; do
        v="${!var:-}"
        if [ -n "$v" ]; then
            PORTS_TO_CHECK+=("$v")
            PORT_LABELS[$v]="$var"
        fi
    done
fi

if [ ${#PORTS_TO_CHECK[@]} -eq 0 ]; then
    warn "no ports to check (.env declares none, no args)"
    exit 0
fi

PROJECT_NAME="${COMPOSE_PROJECT_NAME:-(default)}"
log "Project: ${PROJECT_NAME}"
log "Checking ports: ${PORTS_TO_CHECK[*]}"

# ── Probe each port ──────────────────────────────────────────────────────────
OCCUPIED=()
declare -A OCCUPIED_BY

for port in "${PORTS_TO_CHECK[@]}"; do
    # Docker check first (most informative — tells us which container)
    container=$(docker ps --format '{{.Names}} {{.Ports}}' 2>/dev/null \
        | awk -v p=":${port}->" '$0 ~ p { print $1; exit }')
    if [ -n "$container" ]; then
        OCCUPIED+=("$port")
        OCCUPIED_BY[$port]="docker container: $container"
        continue
    fi

    # Host-level check via lsof (preferred) or netstat fallback
    in_use=false
    if command -v lsof >/dev/null 2>&1; then
        if lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
            in_use=true
            who=$(lsof -nP -iTCP:"$port" -sTCP:LISTEN -F c 2>/dev/null | sed -n 's/^c//p' | head -1)
            OCCUPIED_BY[$port]="host process: ${who:-unknown}"
        fi
    elif command -v ss >/dev/null 2>&1; then
        if ss -ltn 2>/dev/null | awk -v p=":${port}" '$4 ~ p' | grep -q .; then
            in_use=true
            OCCUPIED_BY[$port]="host process (ss; pid unknown — install lsof for detail)"
        fi
    elif command -v netstat >/dev/null 2>&1; then
        if netstat -ltn 2>/dev/null | awk -v p=":${port}" '$4 ~ p' | grep -q .; then
            in_use=true
            OCCUPIED_BY[$port]="host process (netstat; pid unknown — install lsof for detail)"
        fi
    else
        warn "no lsof/ss/netstat available — cannot verify port $port"
        continue
    fi

    if $in_use; then
        OCCUPIED+=("$port")
    fi
done

# ── Report ───────────────────────────────────────────────────────────────────
if [ ${#OCCUPIED[@]} -eq 0 ]; then
    log "✓ All ${#PORTS_TO_CHECK[@]} port(s) free"
    exit 0
fi

err ""
err "Port collision detected — cannot start ${PROJECT_NAME} stack"
err ""
for port in "${OCCUPIED[@]}"; do
    label="${PORT_LABELS[$port]:-(unknown)}"
    by="${OCCUPIED_BY[$port]:-unknown}"
    err "  ✗ port $port (${label}) → in use by ${by}"
done
err ""
err "Resolutions:"
err "  1. Change the conflicting port in .env (e.g. WORDPRESS_PORT=8085)"
err "  2. Stop the other process / container holding the port"
err "  3. Run the conflicting overlay's teardown (docker compose -p <other_project> down)"
err ""
exit 1
