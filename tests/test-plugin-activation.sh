#!/bin/bash

# Plugin Activation Test Suite
# Tests plugin installation, activation, and basic functionality

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_HELPERS="${SCRIPT_DIR}/test-helpers.sh"
PLUGINS_DIR="${SCRIPT_DIR}/../plugins"
REPORTS_DIR="${SCRIPT_DIR}/../reports"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT_FILE="${REPORTS_DIR}/test-report-${TIMESTAMP}.txt"

# Load test helpers
if [ -f "$TEST_HELPERS" ]; then
    source "$TEST_HELPERS"
else
    echo "Error: Test helpers not found at $TEST_HELPERS"
    exit 1
fi

# Function to display usage
usage() {
    echo "Usage: $0 [options] <plugin-zip-file>"
    echo ""
    echo "Options:"
    echo "  -h, --help           Show this help message"
    echo "  -p, --plugin-name <name>  Specify plugin name (default: extracted from zip)"
    echo "  -r, --report <file>  Specify report file (default: auto-generated)"
    echo "  --skip-install       Skip installation, test already installed plugin"
    echo "  --skip-cleanup       Don't cleanup after tests"
    echo ""
    echo "Examples:"
    echo "  $0 elementify-2.0.0.zip"
    echo "  $0 --plugin-name my-plugin ../build/my-plugin.zip"
    exit 0
}

# Function to extract plugin name from ZIP
extract_plugin_name() {
    local zip_file="$1"
    local plugin_name
    
    # Try to get plugin name from ZIP filename
    plugin_name=$(basename "$zip_file" .zip)
    # Remove version patterns
    plugin_name=$(echo "$plugin_name" | sed -E 's/-[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?$//')
    
    echo "$plugin_name"
}

# Function to install plugin
install_plugin() {
    local plugin_zip="$1"
    local plugin_name="$2"
    
    test_header "Plugin Installation"
    
    # Check if plugin ZIP exists
    if [ ! -f "$plugin_zip" ]; then
        test_result "Plugin ZIP Exists" "FAIL" "Plugin ZIP not found: $plugin_zip"
        return 1
    fi
    
    test_result "Plugin ZIP Exists" "PASS" "Found: $plugin_zip"
    
    # Use install-plugin.sh script
    if [ -f "${SCRIPT_DIR}/../scripts/install-plugin.sh" ]; then
        print_status "Installing plugin using install-plugin.sh..."
        if "${SCRIPT_DIR}/../scripts/install-plugin.sh" "$plugin_zip"; then
            test_result "Plugin Installation" "PASS" "Installation script completed"
            return 0
        else
            test_result "Plugin Installation" "FAIL" "Installation script failed"
            return 1
        fi
    else
        test_result "Plugin Installation" "SKIP" "Install script not found, manual install required"
        return 2
    fi
}

# Function to test plugin activation
test_activation() {
    local plugin_name="$1"
    
    test_header "Plugin Activation"
    
    # Wait for WordPress
    if ! wait_for_wordpress; then
        test_result "WordPress Ready" "FAIL" "WordPress not available"
        return 1
    fi
    
    test_result "WordPress Ready" "PASS" "WordPress is accessible"
    
    # Check if plugin is installed
    if check_plugin_installed "$plugin_name"; then
        test_result "Plugin Installed" "PASS" "Plugin is installed in WordPress"
    else
        test_result "Plugin Installed" "FAIL" "Plugin not found in WordPress"
        return 1
    fi
    
    # Check if plugin is active
    if check_plugin_active "$plugin_name"; then
        test_result "Plugin Active" "PASS" "Plugin is active"
    else
        test_result "Plugin Active" "FAIL" "Plugin is not active"
        # Try to activate
        print_status "Attempting to activate plugin..."
        if docker-compose -f ../docker/docker-compose.yml exec -T wp-cli wp plugin activate "$plugin_name"; then
            test_result "Plugin Activation Attempt" "PASS" "Activation command succeeded"
            # Check again
            if check_plugin_active "$plugin_name"; then
                test_result "Plugin Now Active" "PASS" "Plugin activated successfully"
            else
                test_result "Plugin Now Active" "FAIL" "Plugin still not active after activation attempt"
                return 1
            fi
        else
            test_result "Plugin Activation Attempt" "FAIL" "Activation command failed"
            return 1
        fi
    fi
    
    return 0
}

# Function to test REST API
test_rest_api() {
    local plugin_name="$1"
    
    test_header "REST API Testing"
    
    # Get WordPress REST API index
    WORDPRESS_PORT=${WORDPRESS_PORT:-8080}
    REST_URL="http://localhost:$WORDPRESS_PORT/wp-json"
    
    # Check if REST API is accessible
    check_http_status "REST API Access" "$REST_URL" 200
    
    # Check for plugin-specific REST endpoints
    # This would need to be customized per plugin
    print_status "Checking for plugin REST endpoints..."
    
    # Try common REST API patterns
    local endpoints=(
        "/wp-json/$plugin_name/v1"
        "/wp-json/$plugin_name/v2"
        "/wp-json/wp/v2/$plugin_name"
    )
    
    local found_endpoint=0
    for endpoint in "${endpoints[@]}"; do
        local url="http://localhost:$WORDPRESS_PORT$endpoint"
        if curl -s -f "$url" > /dev/null 2>&1; then
            test_result "Plugin REST Endpoint" "PASS" "Found endpoint: $endpoint"
            found_endpoint=1
            break
        fi
    done
    
    if [ $found_endpoint -eq 0 ]; then
        test_result "Plugin REST Endpoint" "SKIP" "No plugin-specific REST endpoints found (may be normal)"
    fi
    
    return 0
}

# Function to test plugin functionality
test_functionality() {
    local plugin_name="$1"
    
    test_header "Basic Functionality"
    
    # Check for PHP errors
    if check_php_errors; then
        test_result "PHP Error Check" "PASS" "No PHP errors in debug log"
    else
        test_result "PHP Error Check" "FAIL" "PHP errors found in debug log"
    fi
    
    # Check WordPress admin area
    WORDPRESS_PORT=${WORDPRESS_PORT:-8080}
    ADMIN_URL="http://localhost:$WORDPRESS_PORT/wp-admin"
    
    check_http_status "Admin Area Access" "$ADMIN_URL" 200
    
    # Check if plugin appears in admin menu (simplistic check)
    print_status "Checking plugin admin presence..."
    # This would need to be customized per plugin
    
    return 0
}

# Function to cleanup after tests
cleanup() {
    local plugin_name="$1"
    local skip_cleanup="${2:-0}"
    
    if [ "$skip_cleanup" = "1" ]; then
        print_status "Skipping cleanup (--skip-cleanup)"
        return 0
    fi
    
    test_header "Cleanup"
    
    # Deactivate plugin
    print_status "Deactivating plugin..."
    if docker-compose -f ../docker/docker-compose.yml exec -T wp-cli wp plugin deactivate "$plugin_name" 2>/dev/null; then
        test_result "Plugin Deactivation" "PASS" "Plugin deactivated"
    else
        test_result "Plugin Deactivation" "SKIP" "Plugin may not have been active"
    fi
    
    # Delete plugin
    print_status "Deleting plugin..."
    if docker-compose -f ../docker/docker-compose.yml exec -T wp-cli wp plugin delete "$plugin_name" 2>/dev/null; then
        test_result "Plugin Deletion" "PASS" "Plugin deleted"
    else
        test_result "Plugin Deletion" "SKIP" "Plugin may not have been installed"
    fi
    
    # Remove plugin files from plugins directory
    local plugin_dir="${PLUGINS_DIR}/${plugin_name}"
    if [ -d "$plugin_dir" ]; then
        print_status "Removing plugin files..."
        rm -rf "$plugin_dir"
        test_result "File Cleanup" "PASS" "Plugin files removed"
    fi
    
    return 0
}

# Function to generate report
generate_report() {
    local plugin_name="$1"
    local report_file="$2"
    
    # Create reports directory
    mkdir -p "$REPORTS_DIR"
    
    # Write report
    {
        echo "=========================================="
        echo "Plugin Test Report"
        echo "=========================================="
        echo "Plugin: $plugin_name"
        echo "Date: $(date)"
        echo "Timestamp: $TIMESTAMP"
        echo "=========================================="
        echo ""
        echo "Test Summary:"
        echo "  Total Tests:  $TOTAL_TESTS"
        echo "  Passed:       $TEST_PASS"
        echo "  Failed:       $TEST_FAIL"
        echo "  Skipped:      $TEST_SKIP"
        echo ""
        echo "=========================================="
        echo "Detailed Results:"
        echo "=========================================="
        # Note: Detailed results would need to be captured during test execution
        # For now, we just include the summary
    } > "$report_file"
    
    print_status "Report generated: $report_file"
}

# Main execution
main() {
    # Parse command line arguments
    PLUGIN_NAME=""
    REPORT_FILE=""
    SKIP_INSTALL=0
    SKIP_CLEANUP=0
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                ;;
            -p|--plugin-name)
                PLUGIN_NAME="$2"
                shift 2
                ;;
            -r|--report)
                REPORT_FILE="$2"
                shift 2
                ;;
            --skip-install)
                SKIP_INSTALL=1
                shift
                ;;
            --skip-cleanup)
                SKIP_CLEANUP=1
                shift
                ;;
            --*|-*)
                print_error "Unknown option: $1"
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
        print_error "Plugin ZIP file required"
        usage
    fi
    
    # Extract plugin name if not provided
    if [ -z "$PLUGIN_NAME" ]; then
        PLUGIN_NAME=$(extract_plugin_name "$PLUGIN_ZIP")
        print_status "Extracted plugin name: $PLUGIN_NAME"
    fi
    
    # Set default report file
    if [ -z "$REPORT_FILE" ]; then
        REPORT_FILE="${REPORTS_DIR}/test-report-${PLUGIN_NAME}-${TIMESTAMP}.txt"
    fi
    
    echo "=========================================="
    echo "Plugin Test Suite"
    echo "=========================================="
    echo "Plugin: $PLUGIN_NAME"
    echo "ZIP File: $PLUGIN_ZIP"
    echo "Report: $REPORT_FILE"
    echo "=========================================="
    
    # Run tests
    local overall_result=0
    
    # Install plugin if not skipping
    if [ "$SKIP_INSTALL" = "0" ]; then
        if ! install_plugin "$PLUGIN_ZIP" "$PLUGIN_NAME"; then
            overall_result=1
        fi
    else
        print_status "Skipping installation (--skip-install)"
    fi
    
    # Test activation
    if ! test_activation "$PLUGIN_NAME"; then
        overall_result=1
    fi
    
    # Test REST API
    if ! test_rest_api "$PLUGIN_NAME"; then
        overall_result=1
    fi
    
    # Test functionality
    if ! test_functionality "$PLUGIN_NAME"; then
        overall_result=1
    fi
    
    # Cleanup
    cleanup "$PLUGIN_NAME" "$SKIP_CLEANUP"
    
    # Generate report
    generate_report "$PLUGIN_NAME" "$REPORT_FILE"
    
    # Display summary
    echo ""
    test_summary
    
    # Return overall result
    if [ $overall_result -eq 0 ]; then
        print_status "All tests completed successfully!"
    else
        print_error "Some tests failed. Check the report for details."
    fi
    
    exit $overall_result
}

# Run main function
main "$@"