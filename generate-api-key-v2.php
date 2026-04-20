<?php
/**
 * Generate Elementify API Key with proper format
 */

// Generate a more realistic API key (like Elementify might generate)
$api_key = 'elementify_' . bin2hex(random_bytes(16));

// Create the key data structure
$key_data = array(
    'key' => $api_key,
    'name' => 'Automated Test Key',
    'permissions' => array('*'), // Wildcard permission for all capabilities
    'created_at' => time(),
    'expires_at' => null,
    'last_used' => null,
    'usage_count' => 0,
    'enabled' => true,
    'user_id' => 1,
    'type' => 'api_key'
);

// Get current API keys
$current_keys = get_option('elementify_mcp_api_keys', array());

// Clear any existing keys first (start fresh)
$current_keys = array();

// Add the new key
$current_keys[$api_key] = $key_data;

// Update the option
$result = update_option('elementify_mcp_api_keys', $current_keys);

// Also update activation mode if needed
update_option('elementify_mcp_activation_mode', 'advanced');

if ($result) {
    echo "API Key generated successfully!\n";
    echo "API Key: " . $api_key . "\n";
    echo "Name: " . $key_data['name'] . "\n";
    echo "Permissions: * (all)\n";
    
    // Output for export
    echo "\nExport command:\n";
    echo "export ELEMENTIFY_API_KEY=\"" . $api_key . "\"\n";
} else {
    echo "Failed to generate API Key.\n";
}

// Flush WordPress cache
wp_cache_flush();

// Try to trigger Elementify to reload its settings
do_action('elementify_api_keys_updated');
?>