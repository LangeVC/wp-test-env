#!/bin/bash
# Script to setup Elementify API key for testing environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    error ".env file not found at $ENV_FILE"
    error "Please copy .env.example to .env and configure it first."
    exit 1
fi

# Check if API key is already set
if grep -q "ELEMENTIFY_API_KEY=" "$ENV_FILE" && [ -n "$(grep "ELEMENTIFY_API_KEY=" "$ENV_FILE" | cut -d= -f2 | tr -d '[:space:]')" ]; then
    log "API key already configured in .env"
    exit 0
fi

log "Setting up Elementify API key..."

# Check if Docker is running and WordPress container is available
if ! docker ps --format '{{.Names}}' | grep -q 'wptesting-wordpress'; then
    warn "WordPress container not found. Starting Docker environment..."
    cd "$PROJECT_DIR" && docker-compose up -d wordpress mysql
    sleep 30 # Wait for services to start
fi

# Check if Elementify plugin is active
if ! docker exec wptesting-wordpress wp plugin is-active elementify --allow-root 2>/dev/null; then
    error "Elementify plugin is not active. Please install and activate it first."
    exit 1
fi

log "Elementify plugin is active."

# Try to generate API key via Elementify REST API
log "Attempting to generate API key via Elementify REST API..."
API_RESPONSE=$(curl -s -k -X POST "http://localhost:8082/wp-json/elementify/v1/auth/generate-key" \
  -H "Content-Type: application/json" \
  -d '{"name":"Testing Environment","permissions":["read","write"]}' 2>/dev/null || true)

if echo "$API_RESPONSE" | grep -q '"api_key"' 2>/dev/null; then
    # Extract API key from response
    API_KEY=$(echo "$API_RESPONSE" | grep -o '"api_key":"[^"]*"' | cut -d'"' -f4)
    log "Generated API key via REST API: $API_KEY"
elif echo "$API_RESPONSE" | grep -q '"error"' 2>/dev/null; then
    warn "REST API key generation failed: $(echo "$API_RESPONSE" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)"
else
    # Try alternative method: check if there's a WP-CLI command
    log "REST API endpoint not found, trying WP-CLI method..."
    CLI_RESPONSE=$(docker exec wptesting-wordpress wp eval "
        // Check if Elementify has API key generation function
        if (function_exists('elementify_generate_api_key')) {
            \$key = elementify_generate_api_key('Testing Environment', ['read', 'write']);
            echo \$key ?: 'NO_KEY_GENERATED';
        } else {
            echo 'NO_FUNCTION';
        }
    " --allow-root 2>/dev/null || echo "CLI_ERROR")
    
    if [ "$CLI_RESPONSE" != "NO_FUNCTION" ] && [ "$CLI_RESPONSE" != "CLI_ERROR" ] && [ "$CLI_RESPONSE" != "NO_KEY_GENERATED" ]; then
        API_KEY="$CLI_RESPONSE"
        log "Generated API key via WP-CLI: $API_KEY"
    else
        # Manual setup required
        warn "Automatic API key generation not available."
        warn "Please generate an API key manually:"
        warn "1. Log into WordPress admin at http://localhost:8082/wp-admin"
        warn "2. Navigate to Elementify → API Keys"
        warn "3. Create a new API key with read/write permissions"
        warn "4. Copy the generated key"
        echo ""
        read -p "Enter your API key: " API_KEY
        
        if [ -z "$API_KEY" ]; then
            error "No API key provided. Tests will fail without authentication."
            exit 1
        fi
    fi
fi

# Update .env file with API key
if [ -n "$API_KEY" ]; then
    # Remove existing ELEMENTIFY_API_KEY line if present
    grep -v "ELEMENTIFY_API_KEY=" "$ENV_FILE" > "${ENV_FILE}.tmp"
    # Add new line
    echo "ELEMENTIFY_API_KEY=$API_KEY" >> "${ENV_FILE}.tmp"
    mv "${ENV_FILE}.tmp" "$ENV_FILE"
    
    log "API key saved to .env file"
    log "Important: Restart Docker containers for changes to take effect:"
    log "  docker-compose restart wordpress"
else
    error "Failed to generate or obtain API key."
    exit 1
fi