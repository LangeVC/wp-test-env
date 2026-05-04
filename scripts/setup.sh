#!/bin/bash
# =============================================================================
# WordPress Testing Environment — One-Click Setup
# =============================================================================
# Usage:
#   ./scripts/setup.sh              # Full setup (Docker + WP + plugins)
#   ./scripts/setup.sh --skip-plugins  # Skip plugin installation
#   ./scripts/setup.sh --fresh          # Destroy volumes and start fresh
#   ./scripts/setup.sh --skip-docker-start  # Skip Docker start (containers already running)
#
# Requirements: Docker with Compose v2 plugin
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="${ROOT_DIR}/docker-compose.yml"
ENV_FILE="${ROOT_DIR}/.env"
COMPOSE_CMD="docker compose"
SKIP_PLUGINS=false
FRESH_START=false
SKIP_DOCKER_START=false

# ── Args ────────────────────────────────────────────────────────────────────
for arg in "$@"; do
    case $arg in
        --skip-plugins)       SKIP_PLUGINS=true ;;
        --fresh)              FRESH_START=true ;;
        --skip-docker-start)  SKIP_DOCKER_START=true ;;
        -h|--help)
            echo "Usage: $0 [--skip-plugins] [--fresh] [--skip-docker-start]"
            exit 0
            ;;
    esac
done

# ── Colors ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
err()   { echo -e "${RED}[✗]${NC} $1"; }

# ── Checks ───────────────────────────────────────────────────────────────────
check_prereqs() {
    if ! docker info > /dev/null 2>&1; then
        err "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    if ! docker compose version > /dev/null 2>&1; then
        err "Docker Compose v2 not found. Please install it."
        exit 1
    fi
    info "Docker and Compose v2 are available."
}

# ── Environment ──────────────────────────────────────────────────────────────
load_env() {
    if [ ! -f "$ENV_FILE" ]; then
        warn ".env not found — creating from .env.example"
        cp "${ROOT_DIR}/.env.example" "$ENV_FILE"
        # Set safe defaults
        cat >> "$ENV_FILE" <<'EOF'
MYSQL_ROOT_PASSWORD=wordpress_root_password
MYSQL_DATABASE=wordpress_test
MYSQL_USER=wordpress
MYSQL_PASSWORD=wordpress_password
MYSQL_PORT=3306
WORDPRESS_PORT=8082
WORDPRESS_TABLE_PREFIX=wp_
WORDPRESS_DEBUG=1
WORDPRESS_DEBUG_DISPLAY=1
WORDPRESS_DEBUG_LOG=1
WORDPRESS_ADMIN_USER=admin
WORDPRESS_ADMIN_PASSWORD=admin
WORDPRESS_ADMIN_EMAIL=admin@example.com
TEST_PLUGIN_PATH=./plugins
TEST_REPORT_PATH=./reports
TEST_TIMEOUT=300
PHPMYADMIN_PORT=8083
MAILHOG_SMTP_PORT=1025
MAILHOG_WEB_PORT=8025
COMPOSE_PROJECT_NAME=wptesting
EOF
        info "Created .env with defaults."
    fi
    set -a; source "$ENV_FILE"; set +a
    info "Environment loaded."
}

# ── Docker ───────────────────────────────────────────────────────────────────
start_containers() {
    if $FRESH_START; then
        warn "Fresh start — destroying existing volumes"
        $COMPOSE_CMD -f "$COMPOSE_FILE" down -v 2>/dev/null || true
    fi
    info "Starting Docker containers..."
    $COMPOSE_CMD -f "$COMPOSE_FILE" up -d --wait
    info "All containers are running."
}

# ── WordPress ────────────────────────────────────────────────────────────────
install_wordpress() {
    local PORT="${WORDPRESS_PORT:-8082}"
    local URL="http://localhost:${PORT}"

    info "Waiting for WordPress at ${URL}..."
    for i in $(seq 1 30); do
        if curl -sf "$URL" > /dev/null 2>&1; then break; fi
        sleep 2
    done
    info "WordPress is reachable."

    # Skip if already installed
    if $COMPOSE_CMD -f "$COMPOSE_FILE" run --rm wp-cli wp core is-installed 2>/dev/null; then
        info "WordPress is already installed."
        return
    fi

    info "Installing WordPress..."
    $COMPOSE_CMD -f "$COMPOSE_FILE" run --rm wp-cli wp core install \
        --url="$URL" \
        --title="WordPress Testing Environment" \
        --admin_user="${WORDPRESS_ADMIN_USER:-admin}" \
        --admin_password="${WORDPRESS_ADMIN_PASSWORD:-admin}" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL:-admin@example.com}" \
        --skip-email

    # Configure
    $COMPOSE_CMD -f "$COMPOSE_FILE" run --rm wp-cli wp option update blogdescription "Local Testing Environment"
    $COMPOSE_CMD -f "$COMPOSE_FILE" run --rm wp-cli wp option update timezone_string "Europe/Berlin"
    $COMPOSE_CMD -f "$COMPOSE_FILE" run --rm wp-cli wp option update permalink_structure "/%postname%/"
    $COMPOSE_CMD -f "$COMPOSE_FILE" run --rm wp-cli wp rewrite flush

    # Create test pages
    $COMPOSE_CMD -f "$COMPOSE_FILE" run --rm wp-cli wp post create \
        --post_type=page --post_title="Home" --post_status=publish \
        --post_content="<!-- wp:paragraph --><p>Test homepage.</p><!-- /wp:paragraph -->"

    # Set as front page
    local HOME_ID=$($COMPOSE_CMD -f "$COMPOSE_FILE" run --rm wp-cli wp post list \
        --post_type=page --post_status=publish --field=ID --title="Home" 2>/dev/null | head -1)
    if [ -n "$HOME_ID" ]; then
        $COMPOSE_CMD -f "$COMPOSE_FILE" run --rm wp-cli wp option update show_on_front page
        $COMPOSE_CMD -f "$COMPOSE_FILE" run --rm wp-cli wp option update page_on_front "$HOME_ID"
    fi

    info "WordPress installed and configured."
}

# ── Plugins ──────────────────────────────────────────────────────────────────
install_plugins() {
    if $SKIP_PLUGINS; then
        info "Skipping plugin installation (--skip-plugins)"
        return
    fi

    local PLUGINS_YAML="${ROOT_DIR}/config/plugins.yaml"
    if [ ! -f "$PLUGINS_YAML" ]; then
        warn "No config/plugins.yaml found — skipping plugin installation."
        return
    fi

    # Check for yq (YAML parser) — fall back to simple grep-based parsing
    local USE_YQ=false
    if command -v yq > /dev/null 2>&1; then
        USE_YQ=true
    fi

    # Install wordpress.org plugins
    info "Installing plugins from config/plugins.yaml..."

    if $USE_YQ; then
        yq '.plugins[] | select(.source == "wordpress.org") | .slug' "$PLUGINS_YAML" | while read -r slug; do
            [ -z "$slug" ] && continue
            info "  Installing ${slug}..."
            $COMPOSE_CMD -f "$COMPOSE_FILE" run --rm wp-cli wp plugin install "$slug" --activate 2>/dev/null || \
                warn "  Failed to install ${slug}"
        done
    else
        # Fallback: extract slugs via grep/sed
        grep -A3 'source: wordpress.org' "$PLUGINS_YAML" | grep 'slug:' | sed 's/.*slug: *//' | while read -r slug; do
            [ -z "$slug" ] && continue
            info "  Installing ${slug}..."
            $COMPOSE_CMD -f "$COMPOSE_FILE" run --rm wp-cli wp plugin install "$slug" --activate 2>/dev/null || \
                warn "  Failed to install ${slug}"
        done
    fi

    # Install local (premium) plugins from vendor-assets/
    if $USE_YQ; then
        yq '.plugins[] | select(.source == "local") | [.slug, .zip_path] | @tsv' "$PLUGINS_YAML" 2>/dev/null | while IFS=$'\t' read -r slug zip_path; do
            [ -z "$slug" ] && continue
            install_local_plugin "$slug" "${ROOT_DIR}/${zip_path}"
        done
    else
        grep -B1 'source: local' "$PLUGINS_YAML" | grep 'slug:' | sed 's/.*slug: *//' | while read -r slug; do
            [ -z "$slug" ] && continue
            local zip_rel=$(grep -A1 "slug: ${slug}" "$PLUGINS_YAML" | grep 'zip_path:' | sed 's/.*zip_path: *//')
            install_local_plugin "$slug" "${ROOT_DIR}/${zip_rel}"
        done
    fi

    info "Plugin installation complete."
}

install_local_plugin() {
    local slug="$1"
    local zip="$2"
    if [ -f "$zip" ]; then
        info "  Installing ${slug} from ${zip}..."
        $COMPOSE_CMD -f "$COMPOSE_FILE" run --rm wp-cli wp plugin install "$zip" --activate 2>/dev/null || \
            warn "  Failed to install ${slug}"
    else
        warn "  Skipping ${slug} — ZIP not found at ${zip}"
    fi
}

# ── Bundles ──────────────────────────────────────────────────────────────────
install_bundles() {
    local PLUGINS_YAML="${ROOT_DIR}/config/plugins.yaml"
    [ -f "$PLUGINS_YAML" ] || return

    if ! command -v yq > /dev/null 2>&1; then
        info "yq not available — skipping bundle installation."
        return
    fi

    local BUNDLE_COUNT=$(yq '.bundles | length' "$PLUGINS_YAML" 2>/dev/null || echo "0")
    if [ "$BUNDLE_COUNT" -gt 0 ] 2>/dev/null; then
        info "Processing bundles..."

        for i in $(seq 0 $((BUNDLE_COUNT - 1))); do
            local BUNDLE_NAME=$(yq ".bundles | keys | .[$i]" "$PLUGINS_YAML")
            local DESC=$(yq ".bundles.\"${BUNDLE_NAME}\".description" "$PLUGINS_YAML")
            info "  Bundle: ${BUNDLE_NAME} — ${DESC}"

            local PLUGIN_COUNT=$(yq ".bundles.\"${BUNDLE_NAME}\".plugins | length" "$PLUGINS_YAML")
            for j in $(seq 0 $((PLUGIN_COUNT - 1))); do
                local P_SLUG=$(yq ".bundles.\"${BUNDLE_NAME}\".plugins[$j].slug" "$PLUGINS_YAML")
                local P_SRC=$(yq ".bundles.\"${BUNDLE_NAME}\".plugins[$j].source" "$PLUGINS_YAML")
                local P_ORDER=$(yq ".bundles.\"${BUNDLE_NAME}\".plugins[$j].install_order" "$PLUGINS_YAML")

                if [ "$P_SRC" = "wordpress.org" ]; then
                    info "    [${P_ORDER}] Installing ${P_SLUG} from wordpress.org..."
                    $COMPOSE_CMD -f "$COMPOSE_FILE" run --rm wp-cli wp plugin install "$P_SLUG" --activate 2>/dev/null || warn "    Failed to install ${P_SLUG}"
                elif [ "$P_SRC" = "local" ]; then
                    local P_ZIP=$(yq ".bundles.\"${BUNDLE_NAME}\".plugins[$j].zip_path" "$PLUGINS_YAML")
                    info "    [${P_ORDER}] Installing ${P_SLUG} from ${P_ZIP}..."
                    $COMPOSE_CMD -f "$COMPOSE_FILE" run --rm wp-cli wp plugin install "${ROOT_DIR}/${P_ZIP}" --activate 2>/dev/null || warn "    Failed to install ${P_SLUG}"
                fi
            done
        done
    fi
}

# ── Summary ──────────────────────────────────────────────────────────────────
show_summary() {
    local PORT="${WORDPRESS_PORT:-8082}"
    echo ""
    echo "══════════════════════════════════════════════"
    echo "  WordPress Testing Environment — Ready"
    echo "══════════════════════════════════════════════"
    echo ""
    echo "  WordPress:    http://localhost:${PORT}"
    echo "  Admin:        http://localhost:${PORT}/wp-admin"
    echo "  phpMyAdmin:   http://localhost:${PHPMYADMIN_PORT:-8083}"
    echo "  MailHog:      http://localhost:${MAILHOG_WEB_PORT:-8025}"
    echo ""
    echo "  Admin User:   ${WORDPRESS_ADMIN_USER:-admin}"
    echo "  Admin Pass:   ${WORDPRESS_ADMIN_PASSWORD:-admin}"
    echo ""
    echo "  WP-CLI:       docker compose run --rm wp-cli wp <cmd>"
    echo "  Logs:         docker compose logs -f wordpress"
    echo "  Stop:         docker compose down"
    echo "  Reset:        docker compose down -v && ./scripts/setup.sh --fresh"
    echo "══════════════════════════════════════════════"
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
    check_prereqs
    load_env
    if $SKIP_DOCKER_START; then
        info "Skipping Docker start (--skip-docker-start)"
    else
        start_containers
    fi
    install_wordpress
    install_plugins
    install_bundles
    show_summary
}

main "$@"
