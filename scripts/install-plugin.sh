#!/bin/bash

# Plugin Installation Script
# Installs a WordPress plugin from a ZIP file into the testing environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="${SCRIPT_DIR}/../plugins"

# Default values
ACTIVATE_PLUGIN=1
SKIP_EXISTING=0

# Function to display usage
usage() {
    echo "Usage: $0 [options] <plugin-zip-file>"
    echo ""
    echo "Options:"
    echo "  -h, --help           Show this help message"
    echo "  -d, --deactivate     Install but don't activate the plugin"
    echo "  -s, --skip-existing  Skip if plugin folder already exists"
    echo "  --name <name>        Specify plugin name (default: extracted from zip)"
    echo ""
    echo "Examples:"
    echo "  $0 elementify-2.0.0.zip"
    echo "  $0 --name my-plugin ../build/my-plugin.zip"
    exit 1
}

# Parse command line arguments
PLUGIN_NAME=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -d|--deactivate)
            ACTIVATE_PLUGIN=0
            shift
            ;;
        -s|--skip-existing)
            SKIP_EXISTING=1
            shift
            ;;
        --name)
            PLUGIN_NAME="$2"
            shift 2
            ;;
        --*|-*)
            echo "Unknown option: $1"
            usage
            ;;
        *)
            PLUGIN_ZIP="$1"
            shift
            ;;
    esac
done

# Check if plugin ZIP was provided
if [ -z "$PLUGIN_ZIP" ]; then
    echo "Error: Plugin ZIP file not specified"
    usage
fi

# Check if file exists
if [ ! -f "$PLUGIN_ZIP" ]; then
    echo "Error: Plugin ZIP file not found: $PLUGIN_ZIP"
    exit 1
fi

# Extract plugin name from ZIP if not provided
if [ -z "$PLUGIN_NAME" ]; then
    # Try to get plugin name from ZIP filename (remove .zip and version)
    PLUGIN_NAME=$(basename "$PLUGIN_ZIP" .zip)
    # Remove version patterns (e.g., -1.0.0, -2.0.0-beta, etc.)
    PLUGIN_NAME=$(echo "$PLUGIN_NAME" | sed -E 's/-[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?$//')
    echo "Extracted plugin name: $PLUGIN_NAME"
fi

PLUGIN_DIR="$PLUGINS_DIR/$PLUGIN_NAME"

# Check if plugin already exists
if [ -d "$PLUGIN_DIR" ] && [ "$SKIP_EXISTING" = "1" ]; then
    echo "Plugin directory already exists: $PLUGIN_DIR"
    echo "Skipping installation (--skip-existing)"
    exit 0
fi

echo "=========================================="
echo "Installing Plugin: $PLUGIN_NAME"
echo "=========================================="
echo "Source ZIP: $PLUGIN_ZIP"
echo "Target Dir: $PLUGIN_DIR"
echo "Activate: $([ "$ACTIVATE_PLUGIN" = "1" ] && echo "Yes" || echo "No")"
echo "=========================================="

# Clean up existing directory if it exists
if [ -d "$PLUGIN_DIR" ]; then
    echo "Removing existing plugin directory..."
    rm -rf "$PLUGIN_DIR"
fi

# Create plugins directory if it doesn't exist
mkdir -p "$PLUGINS_DIR"

# Extract plugin ZIP
echo "Extracting plugin..."
if ! unzip -q "$PLUGIN_ZIP" -d "$PLUGINS_DIR"; then
    echo "Error: Failed to extract plugin ZIP"
    exit 1
fi

# Check if extraction created the expected directory
if [ ! -d "$PLUGIN_DIR" ]; then
    # Sometimes ZIPs contain a single directory with the plugin files
    # List directories in plugins to find the new one
    NEW_DIR=$(find "$PLUGINS_DIR" -maxdepth 1 -type d -newer "$PLUGINS_DIR" | head -1)
    if [ -n "$NEW_DIR" ] && [ "$NEW_DIR" != "$PLUGINS_DIR" ]; then
        echo "Plugin extracted to: $NEW_DIR"
        # Rename to expected name
        mv "$NEW_DIR" "$PLUGIN_DIR"
    else
        echo "Error: Plugin extraction didn't create expected directory structure"
        echo "Contents of plugins directory:"
        ls -la "$PLUGINS_DIR"
        exit 1
    fi
fi

echo "Plugin files extracted successfully."

# Activate plugin if requested
if [ "$ACTIVATE_PLUGIN" = "1" ]; then
    echo "Activating plugin..."
    
    # Wait for WordPress to be ready
    echo "Checking WordPress availability..."
    MAX_ATTEMPTS=10
    ATTEMPT=1
    WORDPRESS_PORT=${WORDPRESS_PORT:-8080}
    
    while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
        if curl -s -f "http://localhost:$WORDPRESS_PORT" > /dev/null; then
            echo "WordPress is ready."
            break
        fi
        echo "Attempt $ATTEMPT/$MAX_ATTEMPTS: WordPress not ready yet..."
        if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
            echo "Warning: WordPress not responding, plugin activation may fail"
        fi
        sleep 2
        ATTEMPT=$((ATTEMPT + 1))
    done
    
    # Activate using WP-CLI
    if docker-compose -f ../docker/docker-compose.yml ps | grep -q "wp-test-wordpress.*Up"; then
        echo "Activating $PLUGIN_NAME via WP-CLI..."
        if docker-compose -f ../docker/docker-compose.yml exec -T wp-cli wp plugin is-installed "$PLUGIN_NAME"; then
            docker-compose -f ../docker/docker-compose.yml exec -T wp-cli wp plugin activate "$PLUGIN_NAME"
            echo "Plugin activated successfully."
            
            # Check for activation errors
            if docker-compose -f ../docker/docker-compose.yml exec -T wp-cli wp plugin is-active "$PLUGIN_NAME"; then
                echo "Plugin is active and running."
            else
                echo "Warning: Plugin activation may have failed."
                echo "Check WordPress error logs for details."
            fi
        else
            echo "Error: Plugin '$PLUGIN_NAME' not found by WordPress."
            echo "Plugin directory exists at: $PLUGIN_DIR"
            echo "Listing plugin files:"
            ls -la "$PLUGIN_DIR"
        fi
    else
        echo "Error: WordPress container is not running."
        echo "Start the environment with: docker-compose -f ../docker/docker-compose.yml up -d"
        exit 1
    fi
fi

echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo "Plugin: $PLUGIN_NAME"
echo "Location: $PLUGIN_DIR"
if [ "$ACTIVATE_PLUGIN" = "1" ]; then
    echo "Status: Installed and Activated"
else
    echo "Status: Installed (not activated)"
fi
echo ""
echo "Next steps:"
echo "1. Visit WordPress admin: http://localhost:${WORDPRESS_PORT:-8080}/wp-admin"
echo "2. Test the plugin functionality"
echo "3. Check debug logs if needed: docker-compose -f ../docker/docker-compose.yml logs wordpress"
echo "=========================================="