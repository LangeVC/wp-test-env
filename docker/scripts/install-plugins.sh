#!/bin/bash
# Container-side plugin installer
# Called by scripts/setup.sh to install plugins from config/plugins.yaml
# Runs INSIDE the wp-cli container.

set -e

PLUGIN_LIST="$1"

if [ -z "$PLUGIN_LIST" ]; then
    echo "Usage: install-plugins.sh <plugin-list-file>"
    echo "  plugin-list-file: newline-separated list of plugin slugs to install"
    exit 1
fi

while IFS= read -r slug; do
    [ -z "$slug" ] && continue
    echo "Installing: $slug"
    wp plugin install "$slug" --activate || echo "  WARNING: Failed to install $slug"
done < "$PLUGIN_LIST"
