#!/bin/bash
# Install plugins directly in WordPress container

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

COMPOSE_PROJECT="${COMPOSE_PROJECT_NAME:-wptesting}"
cd "$SCRIPT_DIR"

echo "Installing plugins for project: $COMPOSE_PROJECT..."

# Copy plugin zips to container
for plugin_zip in plugins/*.zip; do
    if [ -f "$plugin_zip" ]; then
        plugin_name=$(basename "$plugin_zip" .zip)
        echo "Installing $plugin_name..."
        
        # Copy to container
        docker cp "$plugin_zip" ${COMPOSE_PROJECT}-wordpress:/tmp/
        
        # Extract in container (WordPress container doesn't have unzip, use PHP)
        docker-compose -f docker-compose.yml exec -T ${COMPOSE_PROJECT}-wordpress bash -c "
            cd /tmp && 
            php -r '\$zip = new ZipArchive; \$res = \$zip->open(\"$plugin_name.zip\"); if (\$res === TRUE) { \$zip->extractTo(\"/var/www/html/wp-content/plugins/\"); \$zip->close(); echo \"Extracted $plugin_name\n\"; } else { echo \"Failed to extract $plugin_name\n\"; }'
        " || echo "Warning: Failed to extract $plugin_name"
    fi
done

echo "Plugin installation complete!"
echo ""
echo "To activate plugins, use:"
echo "  docker-compose run --rm ${COMPOSE_PROJECT}-wp-cli wp plugin activate <plugin-name>"
echo ""
echo "To list installed plugins:"
echo "  docker-compose run --rm ${COMPOSE_PROJECT}-wp-cli wp plugin list"