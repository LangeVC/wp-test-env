<?php
/**
 * Generate Elementify API Key and add to options
 */

// Generate a random API key (32 characters)
$api_key = 'test-' . bin2hex(random_bytes(16));

// Create the key data structure
$key_data = array(
    'key' => $api_key,
    'name' => 'Test API Key for Automated Testing',
    'permissions' => array(
        'site-audit:read',
        'stack-bootstrap:read',
        'stack-bootstrap:prepare',
        'stack-bootstrap:write',
        'site-foundation:read',
        'site-foundation:write',
        'design-system:read',
        'design-system:write',
        'content-structure:read',
        'content-structure:write',
        'theme-structure:read',
        'theme-structure:write',
        'library-operations:read',
        'library-operations:write',
        'library-operations:import',
        'library-operations:export',
        'media-operations:read',
        'media-operations:write',
        'plugin-stack-context:read',
        'plugin-stack-context:prepare',
        'governance:read',
        'governance:review',
        'governance:apply',
        'governance:write',
        'governance:queue',
        'ally:read',
        'ally:trigger',
        'translate:read',
        'translate:write',
        'lms:read',
        'charity:read',
        'booking:read',
        'booking:write',
        'diagnostics:read',
        'diagnostics:write',
        'workflow-orchestration:read',
        'workflow-orchestration:prepare',
        'workflow-orchestration:write',
        'site-settings:read',
        'site-settings:write',
        'seo-operations:read',
        'seo-operations:write',
        'performance-operations:read',
        'performance-operations:write',
        'ecommerce-operations:read',
        'ecommerce-operations:write'
    ),
    'created_at' => time(),
    'expires_at' => null, // Never expires
    'last_used' => null,
    'usage_count' => 0,
    'enabled' => true
);

// Get current API keys
$current_keys = get_option('elementify_mcp_api_keys', array());

// Add the new key
$current_keys[$api_key] = $key_data;

// Update the option
$result = update_option('elementify_mcp_api_keys', $current_keys);

if ($result) {
    echo "API Key generated successfully!\n";
    echo "API Key: " . $api_key . "\n";
    echo "Name: " . $key_data['name'] . "\n";
    echo "Permissions: " . count($key_data['permissions']) . " capabilities\n";
    
    // Also output as environment variable format
    echo "\nExport command:\n";
    echo "export ELEMENTIFY_API_KEY=\"" . $api_key . "\"\n";
} else {
    echo "Failed to generate API Key.\n";
    error_log("Failed to update elementify_mcp_api_keys option");
}

// Also test if the key works by making a simple API call
$test_url = home_url('/wp-json/elementify/v1/site');
$response = wp_remote_get($test_url, array(
    'headers' => array(
        'X-API-Key' => $api_key
    )
));

if (!is_wp_error($response) && wp_remote_retrieve_response_code($response) === 200) {
    echo "\nAPI Key test: SUCCESS (HTTP 200)\n";
} else {
    echo "\nAPI Key test: FAILED (may need to restart WordPress or wait for cache)\n";
    if (is_wp_error($response)) {
        echo "Error: " . $response->get_error_message() . "\n";
    } else {
        echo "HTTP Code: " . wp_remote_retrieve_response_code($response) . "\n";
    }
}
?>