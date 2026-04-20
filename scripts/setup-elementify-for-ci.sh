#!/bin/bash
# Setup Elementify plugin and generate API key for CI/CD
# This script should be run after WordPress and plugins are installed

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "🔧 Setting up Elementify plugin for CI/CD..."

# Activate Elementify plugin
echo "📦 Activating Elementify plugin..."
docker compose exec -T wordpress wp plugin activate elementify --allow-root

# Wait for plugin to be fully loaded
sleep 5

# Generate API key using WP-CLI
echo "🔑 Generating Elementify API key..."
API_KEY=$(docker compose exec -T wordpress wp eval '
use Elementify\MCP\Auth\Capabilities;
$all_caps = Capabilities::all();
$api_key = "ek_" . bin2hex(random_bytes(24));
$key_data = [
    "key" => $api_key,
    "label" => "CI/CD Test Key",
    "capabilities" => $all_caps,
    "created_at" => gmdate("c"),
    "last_used" => null,
    "is_active" => true,
];
$keys = get_option("elementify_mcp_api_keys", []);
$keys = [$key_data];
update_option("elementify_mcp_api_keys", $keys);
update_option("elementify_mcp_activation_mode", "advanced");
$governance = get_option("elementify_mcp_governance", []);
$governance["allowed_capabilities"] = $all_caps;
$governance["require_approval"] = false;
$governance["audit_log_enabled"] = true;
$governance["max_keys"] = 10;
update_option("elementify_mcp_governance", $governance);
wp_cache_flush();
do_action("elementify_api_keys_updated");
echo $api_key;
' --allow-root)

if [ -z "$API_KEY" ]; then
    echo "❌ Failed to generate API key"
    exit 1
fi

echo "✅ Elementify API Key generated: $API_KEY"

# Save API key to file for use in CI
echo "$API_KEY" > /tmp/elementify_ci_api_key.txt
echo "📄 API key saved to /tmp/elementify_ci_api_key.txt"

# Export for current shell
export ELEMENTIFY_API_KEY="$API_KEY"
echo "📋 Export for current shell:"
echo "export ELEMENTIFY_API_KEY=\"$API_KEY\""

# Test the API key
echo "🧪 Testing API key..."
TEST_RESULT=$(curl -s -o /dev/null -w "%{http_code}" -H "X-Elementify-Key: $API_KEY" http://localhost:8082/wp-json/elementify/v1/templates)

if [ "$TEST_RESULT" = "200" ]; then
    echo "✅ API key test successful (HTTP $TEST_RESULT)"
else
    echo "⚠️  API key test returned HTTP $TEST_RESULT (might be okay if no templates exist)"
fi

# Output GitHub Actions workflow step
echo ""
echo "📋 For GitHub Actions, add these steps to your workflow:"
echo "  - name: Setup Elementify API key"
echo "    run: |"
echo "      docker compose exec -T wordpress wp plugin activate elementify --allow-root"
echo "      sleep 5"
echo "      ELEMENTIFY_API_KEY=\$(docker compose exec -T wordpress wp eval '...' --allow-root)"
echo "      echo \"ELEMENTIFY_API_KEY=\$ELEMENTIFY_API_KEY\" >> \$GITHUB_ENV"

echo ""
echo "🎉 Elementify setup complete!"