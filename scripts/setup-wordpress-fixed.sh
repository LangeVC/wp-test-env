#!/bin/bash

# WordPress Testing Environment Setup Script
# Installs WordPress and configures it for testing

set -e

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"

if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
    echo "Loaded environment from $ENV_FILE"
else
    echo "Warning: .env file not found at $ENV_FILE, using defaults"
fi

# Default values
WORDPRESS_URL="http://localhost:${WORDPRESS_PORT:-8082}"
WORDPRESS_TITLE="WordPress Testing Environment"
WORDPRESS_ADMIN_USER="${WORDPRESS_ADMIN_USER:-admin}"
WORDPRESS_ADMIN_PASSWORD="${WORDPRESS_ADMIN_PASSWORD:-admin}"
WORDPRESS_ADMIN_EMAIL="${WORDPRESS_ADMIN_EMAIL:-admin@example.com}"
COMPOSE_PROJECT="${COMPOSE_PROJECT_NAME:-wptesting}"

echo "=========================================="
echo "WordPress Testing Environment Setup"
echo "=========================================="
echo "WordPress URL: $WORDPRESS_URL"
echo "Admin User: $WORDPRESS_ADMIN_USER"
echo "Admin Email: $WORDPRESS_ADMIN_EMAIL"
echo "Project: $COMPOSE_PROJECT"
echo "=========================================="

# Wait for WordPress to be ready
echo "Waiting for WordPress to be ready..."
MAX_ATTEMPTS=30
ATTEMPT=1
while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    if curl -s -f "$WORDPRESS_URL" > /dev/null; then
        echo "WordPress is ready!"
        break
    fi
    echo "Attempt $ATTEMPT/$MAX_ATTEMPTS: WordPress not ready yet..."
    if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
        echo "ERROR: WordPress failed to start after $MAX_ATTEMPTS attempts"
        exit 1
    fi
    sleep 2
    ATTEMPT=$((ATTEMPT + 1))
done

# Additional wait for database connectivity
echo "Checking database connectivity..."
MAX_DB_ATTEMPTS=10
DB_ATTEMPT=1
while [ $DB_ATTEMPT -le $MAX_DB_ATTEMPTS ]; do
    if docker-compose -f "${SCRIPT_DIR}/../docker-compose.yml" run --rm wp-cli wp db check 2>/dev/null | grep -q "Success"; then
        echo "Database connection OK!"
        break
    fi
    echo "Database attempt $DB_ATTEMPT/$MAX_DB_ATTEMPTS: Waiting for database..."
    if [ $DB_ATTEMPT -eq $MAX_DB_ATTEMPTS ]; then
        echo "WARNING: Database connectivity check failed, continuing anyway..."
    fi
    sleep 3
    DB_ATTEMPT=$((DB_ATTEMPT + 1))
done

# Install WordPress using WP-CLI
echo "Installing WordPress..."
docker-compose -f "${SCRIPT_DIR}/../docker-compose.yml" run --rm wp-cli wp core install \
    --url="$WORDPRESS_URL" \
    --title="$WORDPRESS_TITLE" \
    --admin_user="$WORDPRESS_ADMIN_USER" \
    --admin_password="$WORDPRESS_ADMIN_PASSWORD" \
    --admin_email="$WORDPRESS_ADMIN_EMAIL" \
    --skip-email

# Update WordPress options for testing
echo "Configuring WordPress for testing..."
docker-compose -f "${SCRIPT_DIR}/../docker-compose.yml" run --rm wp-cli wp option update blogdescription "Local Testing Environment"
docker-compose -f "${SCRIPT_DIR}/../docker-compose.yml" run --rm wp-cli wp option update timezone_string "Europe/Berlin"
docker-compose -f "${SCRIPT_DIR}/../docker-compose.yml" run --rm wp-cli wp option update date_format "Y-m-d"
docker-compose -f "${SCRIPT_DIR}/../docker-compose.yml" run --rm wp-cli wp option update time_format "H:i"
docker-compose -f "${SCRIPT_DIR}/../docker-compose.yml" run --rm wp-cli wp option update permalink_structure "/%postname%/"

# Enable debugging in wp-config.php
echo "Enabling debugging..."
docker-compose -f "${SCRIPT_DIR}/../docker-compose.yml" run --rm wp-cli wp config set WP_DEBUG true --raw
docker-compose -f "${SCRIPT_DIR}/../docker-compose.yml" run --rm wp-cli wp config set WP_DEBUG_DISPLAY true --raw
docker-compose -f "${SCRIPT_DIR}/../docker-compose.yml" run --rm wp-cli wp config set WP_DEBUG_LOG true --raw
docker-compose -f "${SCRIPT_DIR}/../docker-compose.yml" run --rm wp-cli wp config set SCRIPT_DEBUG true --raw
docker-compose -f "${SCRIPT_DIR}/../docker-compose.yml" run --rm wp-cli wp config set SAVEQUERIES true --raw

# Note: Plugins are already installed via install-plugins.sh
echo "Plugins should be installed via install-plugins.sh script"

# Create test content
echo "Creating test content..."
docker-compose -f "${SCRIPT_DIR}/../docker-compose.yml" run --rm wp-cli wp post create \
    --post_type=page \
    --post_title="Homepage" \
    --post_content="<!-- wp:paragraph --><p>This is the homepage of the testing environment.</p><!-- /wp:paragraph -->" \
    --post_status=publish

docker-compose -f "${SCRIPT_DIR}/../docker-compose.yml" run --rm wp-cli wp post create \
    --post_type=page \
    --post_title="About" \
    --post_content="<!-- wp:paragraph --><p>About page for testing.</p><!-- /wp:paragraph -->" \
    --post_status=publish

docker-compose -f "${SCRIPT_DIR}/../docker-compose.yml" run --rm wp-cli wp post create \
    --post_type=page \
    --post_title="Contact" \
    --post_content="<!-- wp:paragraph --><p>Contact page for testing.</p><!-- /wp:paragraph -->" \
    --post_status=publish

# Set homepage - find homepage ID
echo "Setting homepage..."
HOMEPAGE_ID=$(docker-compose -f "${SCRIPT_DIR}/../docker-compose.yml" run --rm wp-cli wp post list --post_type=page --post_status=publish --field=ID --title="Homepage" 2>/dev/null | head -1)
if [ -n "$HOMEPAGE_ID" ]; then
    docker-compose -f "${SCRIPT_DIR}/../docker-compose.yml" run --rm wp-cli wp option update show_on_front page
    docker-compose -f "${SCRIPT_DIR}/../docker-compose.yml" run --rm wp-cli wp option update page_on_front "$HOMEPAGE_ID"
    echo "Homepage set to ID: $HOMEPAGE_ID"
else
    echo "WARNING: Could not find Homepage to set as front page"
fi

# Create test users
echo "Creating test users..."
docker-compose -f "${SCRIPT_DIR}/../docker-compose.yml" run --rm wp-cli wp user create editor editor@example.com --role=editor --user_pass=editor
docker-compose -f "${SCRIPT_DIR}/../docker-compose.yml" run --rm wp-cli wp user create author author@example.com --role=author --user_pass=author
docker-compose -f "${SCRIPT_DIR}/../docker-compose.yml" run --rm wp-cli wp user create subscriber subscriber@example.com --role=subscriber --user_pass=subscriber

echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo "WordPress URL: $WORDPRESS_URL"
echo "Admin URL: $WORDPRESS_URL/wp-admin"
echo "Admin User: $WORDPRESS_ADMIN_USER"
echo "Admin Password: $WORDPRESS_ADMIN_PASSWORD"
echo ""
echo "Services:"
echo "- WordPress: $WORDPRESS_URL"
echo "- phpMyAdmin: http://localhost:${PHPMYADMIN_PORT:-8083}"
echo "- MailHog: http://localhost:${MAILHOG_WEB_PORT:-8025}"
echo "=========================================="