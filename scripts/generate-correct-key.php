<?php
/**
 * Generate Elementify API Key with correct format matching plugin structure
 * 
 * This script creates a key with the exact structure expected by the Elementify plugin:
 * - label (not name)
 * - capabilities (not permissions)
 * - is_active (not enabled)
 * - created_at as ISO string
 * - No extra fields like expires_at, usage_count, user_id, type
 */

// Include WordPress (run from within WordPress environment)
define('WP_USE_THEMES', false);
require_once('/var/www/html/wp-load.php');

// Generate API key similar to plugin's format: 'ek_' + 48 hex chars
$api_key = 'ek_' . bin2hex(random_bytes(24));

// Create the key data structure matching plugin's generate_key() method
$key_data = array(
    'key' => $api_key,
    'label' => 'Automated Test Key',
    'capabilities' => array('*'), // Wildcard for all capabilities
    'created_at' => gmdate('c'), // ISO 8601 format
    'last_used' => null,
    'is_active' => true,
);

// Get current API keys
$current_keys = get_option('elementify_mcp_api_keys', array());

// Check if keys is an associative array with key as index
// Plugin stores as numeric array, but our previous script used associative
// Let's convert to numeric array if needed
if (!empty($current_keys) && !isset($current_keys[0])) {
    // This is an associative array, convert to numeric
    $current_keys = array_values($current_keys);
}

// Add the new key to the array (plugin uses $keys[] = $record)
$current_keys[] = $key_data;

// Update the option
$result = update_option('elementify_mcp_api_keys', $current_keys);

// Also ensure activation mode is advanced
update_option('elementify_mcp_activation_mode', 'advanced');

// Ensure governance allows all capabilities
$governance = get_option('elementify_mcp_governance', array());
if (empty($governance['allowed_capabilities']) || !in_array('*', $governance['allowed_capabilities'])) {
    $governance['allowed_capabilities'] = array('*');
    update_option('elementify_mcp_governance', $governance);
}

if ($result) {
    echo "✅ API Key generated successfully with correct format!\n";
    echo "API Key: " . $api_key . "\n";
    echo "Label: " . $key_data['label'] . "\n";
    echo "Capabilities: * (all)\n";
    echo "is_active: true\n";
    echo "created_at: " . $key_data['created_at'] . "\n";
    
    // Output for export
    echo "\n📋 Export command:\n";
    echo "export ELEMENTIFY_API_KEY=\"" . $api_key . "\"\n";
    
    // Also output curl test command
    echo "\n🔍 Test command:\n";
    echo "curl -H \"X-Elementify-Key: " . $api_key . "\" http://localhost:8082/wp-json/elementify/v1/templates\n";
} else {
    echo "❌ Failed to generate API Key.\n";
}

// Flush WordPress cache
wp_cache_flush();

// Trigger action for plugin to reload settings
do_action('elementify_api_keys_updated');

// Output current keys count
echo "\n📊 Total API keys: " . count($current_keys) . "\n";
?>