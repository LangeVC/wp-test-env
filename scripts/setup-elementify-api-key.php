<?php
/**
 * Elementify API Key Setup Script
 * 
 * Generates a fully functional API key with all required capabilities
 * and correct data structure for the Elementify plugin.
 * 
 * Usage: Run this script within WordPress environment (wp eval-file or via wp-cli)
 */

// Prevent direct access
if (!defined('ABSPATH')) {
    echo "❌ This script must be run within WordPress.\n";
    exit(1);
}

// Use the Elementify capabilities class
use Elementify\MCP\Auth\Capabilities;

// Generate API key in plugin's format
$api_key = 'ek_' . bin2hex(random_bytes(24));

// Get all capabilities
$all_capabilities = Capabilities::all();

// Create key data structure matching plugin's generate_key() method
$key_data = [
    'key' => $api_key,
    'label' => 'Full Access Test Key',
    'capabilities' => $all_capabilities,
    'created_at' => gmdate('c'),
    'last_used' => null,
    'is_active' => true,
];

// Get current API keys
$current_keys = get_option('elementify_mcp_api_keys', []);

// Convert associative to numeric array if needed (from previous script versions)
if (!empty($current_keys) && !isset($current_keys[0])) {
    $current_keys = array_values($current_keys);
}

// Clear any existing keys and add our new one
$current_keys = [$key_data];

// Update the option
$result = update_option('elementify_mcp_api_keys', $current_keys);

// Ensure activation mode is advanced
update_option('elementify_mcp_activation_mode', 'advanced');

// Update governance to allow all capabilities
$governance = get_option('elementify_mcp_governance', []);
$governance['allowed_capabilities'] = $all_capabilities;
$governance['require_approval'] = false;
$governance['audit_log_enabled'] = true;
$governance['max_keys'] = 10;
update_option('elementify_mcp_governance', $governance);

// Flush cache and trigger plugin reload
wp_cache_flush();
do_action('elementify_api_keys_updated');

if ($result) {
    echo "✅ Elementify API Key setup complete!\n";
    echo "========================================\n";
    echo "API Key: " . $api_key . "\n";
    echo "Label: " . $key_data['label'] . "\n";
    echo "Capabilities: " . count($all_capabilities) . " total\n";
    echo "Activation Mode: advanced\n";
    echo "Governance: All capabilities allowed\n";
    echo "\n📋 Export command:\n";
    echo "export ELEMENTIFY_API_KEY=\"" . $api_key . "\"\n";
    echo "\n🔍 Quick test:\n";
    echo "curl -H \"X-Elementify-Key: " . $api_key . "\" http://localhost:8082/wp-json/elementify/v1/templates\n";
    
    // Also save to a temporary file for CI/CD use
    file_put_contents('/tmp/elementify_api_key.txt', $api_key);
    echo "\n📄 API key saved to /tmp/elementify_api_key.txt\n";
} else {
    echo "❌ Failed to setup API Key.\n";
    exit(1);
}

?>