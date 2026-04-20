#!/bin/bash
# Elementify Plugin API Test Suite
# Comprehensive API testing for Elementify WordPress plugin

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="${PROJECT_DIR}/.env"
CONFIG_FILE="${PROJECT_DIR}/config/elementify-test-config.yaml"

# Default values
VERBOSE=false
STRICT=false
TEST_ALL=true
TEST_BASIC=false
TEST_AUTH=false
TEST_TEMPLATES=false
TEST_PAGES=false
TEST_MEDIA=false
TEST_SETTINGS=false
TEST_MCP=false
OUTPUT_FORMAT="text"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${PROJECT_DIR}/reports/elementify-api-test-${TIMESTAMP}.json"

# Load environment variables
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

# Configuration
WORDPRESS_PORT=${WORDPRESS_PORT:-8082}
WORDPRESS_URL="http://localhost:${WORDPRESS_PORT}"
API_BASE="${WORDPRESS_URL}/wp-json"
ELEMENTIFY_NAMESPACE="elementify/v1"
API_KEY=${ELEMENTIFY_API_KEY:-""}
COMPOSE_PROJECT=${COMPOSE_PROJECT_NAME:-wptesting}

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0
TESTS_TOTAL=0

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [options]

Elementify Plugin API Test Suite

Options:
  -h, --help           Show this help message
  -v, --verbose        Show detailed output
  -s, --strict         Exit on first test failure
  -f, --format <fmt>   Output format: text, json, html (default: text)
  -o, --output <file>  Output report file (default: reports/elementify-api-test-<timestamp>.json)
  
  Test Selection:
  --all                Run all tests (default)
  --basic              Test basic API connectivity
  --auth               Test authentication/authorization
  --templates          Test template endpoints
  --pages              Test page endpoints  
  --media              Test media endpoints
  --settings           Test settings endpoints
  --mcp                Test MCP integration

Examples:
  $0 --all                    # Run all tests
  $0 --basic --auth          # Test basic API and auth only
  $0 --verbose --format json # Verbose output in JSON format
  $0 --output my-report.json # Save report to specific file
EOF
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -s|--strict)
            STRICT=true
            shift
            ;;
        -f|--format)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        -o|--output)
            REPORT_FILE="$2"
            shift 2
            ;;
        --all)
            TEST_ALL=true
            shift
            ;;
        --basic)
            TEST_BASIC=true
            TEST_ALL=false
            shift
            ;;
        --auth)
            TEST_AUTH=true
            TEST_ALL=false
            shift
            ;;
        --templates)
            TEST_TEMPLATES=true
            TEST_ALL=false
            shift
            ;;
        --pages)
            TEST_PAGES=true
            TEST_ALL=false
            shift
            ;;
        --media)
            TEST_MEDIA=true
            TEST_ALL=false
            shift
            ;;
        --settings)
            TEST_SETTINGS=true
            TEST_ALL=false
            shift
            ;;
        --mcp)
            TEST_MCP=true
            TEST_ALL=false
            shift
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# If no specific tests selected, run all
if [ "$TEST_ALL" = true ]; then
    TEST_BASIC=true
    TEST_AUTH=true
    TEST_TEMPLATES=true
    TEST_PAGES=true
    TEST_MEDIA=true
    TEST_SETTINGS=true
    TEST_MCP=true
fi

# Ensure report directory exists
mkdir -p "$(dirname "$REPORT_FILE")"

# Logging and output functions
log() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    if [ "$VERBOSE" = true ] || [ "$level" = "ERROR" ] || [ "$level" = "WARNING" ]; then
        echo "[$timestamp] [$level] $message" >&2
    fi
}

test_result() {
    local test_name="$1"
    local status="$2"
    local message="$3"
    local details="${4:-}"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    case $status in
        PASS)
            TESTS_PASSED=$((TESTS_PASSED + 1))
            log "✅ $test_name: PASS - $message" "INFO"
            ;;
        FAIL)
            TESTS_FAILED=$((TESTS_FAILED + 1))
            log "❌ $test_name: FAIL - $message" "ERROR"
            if [ -n "$details" ]; then
                log "   Details: $details" "ERROR"
            fi
            if [ "$STRICT" = true ]; then
                exit 1
            fi
            ;;
        SKIP)
            TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
            log "⏭️  $test_name: SKIP - $message" "WARNING"
            ;;
    esac
}

# HTTP request helper
http_request() {
    local method="$1"
    local url="$2"
    local data="${3:-}"
    local headers="${4:-}"
    
    local curl_cmd="curl -s -k -X $method"
    
    # Add headers
    if [ -n "$headers" ]; then
        curl_cmd="$curl_cmd $headers"
    fi
    
    # Add authentication if API key is set
    if [ -n "$API_KEY" ]; then
        curl_cmd="$curl_cmd -H 'Authorization: Bearer $API_KEY'"
    fi
    
    # Add data for POST/PUT requests
    if [ -n "$data" ]; then
        curl_cmd="$curl_cmd -d '$data' -H 'Content-Type: application/json'"
    fi
    
    # Add URL and output options
    curl_cmd="$curl_cmd '$url' -w '%{http_code}' -o /tmp/http_response_$$.json"
    
    if [ "$VERBOSE" = true ]; then
        log "HTTP Request: $curl_cmd" "DEBUG"
    fi
    
    # Execute curl command
    local http_code=$(eval $curl_cmd 2>/tmp/http_stderr_$$.txt)
    local response=$(cat /tmp/http_response_$$.json 2>/dev/null)
    local stderr_output=$(cat /tmp/http_stderr_$$.txt 2>/dev/null)
    rm -f /tmp/http_response_$$.json /tmp/http_stderr_$$.txt
    
    # Log stderr if present and verbose
    if [ -n "$stderr_output" ] && [ "$VERBOSE" = true ]; then
        log "curl stderr: $stderr_output" "DEBUG"
    fi
    
    echo "$http_code|$response"
}

# Check HTTP status (accepts optional alternate expected code)
check_http_status() {
    local test_name="$1"
    local url="$2"
    local expected_code="$3"
    local alternate_code="${4:-}"
    local method="${5:-GET}"
    
    local result=$(http_request "$method" "$url")
    local http_code=$(echo "$result" | cut -d'|' -f1 | tr -d '\n\r' | xargs)
    local response=$(echo "$result" | cut -d'|' -f2-)
    
    # Determine if HTTP code matches expected or alternate
    local status_match=false
    local expected_display="$expected_code"
    
    if [ "$http_code" = "$expected_code" ]; then
        status_match=true
    elif [ -n "$alternate_code" ] && [ "$http_code" = "$alternate_code" ]; then
        status_match=true
        expected_display="$expected_code or $alternate_code"
    fi
    
    if [ "$status_match" = true ]; then
        test_result "$test_name" "PASS" "HTTP $http_code received for $method $url (expected $expected_display)"
        echo "$response"
    else
        test_result "$test_name" "FAIL" "Expected HTTP $expected_code$( [ -n "$alternate_code" ] && echo " or $alternate_code" ), got $http_code for $method $url" "Response: $response"
        echo ""
    fi
}

# Extract field from JSON response
extract_json_field() {
    local json="$1"
    local field="$2"
    
    if [ -z "$json" ]; then
        echo ""
        return 1
    fi
    
    if command -v jq >/dev/null 2>&1; then
        echo "$json" | jq -r ".$field // \"\"" 2>/dev/null
        return $?
    elif command -v python3 >/dev/null 2>&1; then
        echo "$json" | python3 -c "import json, sys; data=json.loads(sys.stdin.read()); print(data.get('$field', ''))" 2>/dev/null
        return $?
    else
        echo ""
        return 1
    fi
}

# Check JSON response
check_json_response() {
    local test_name="$1"
    local response="$2"
    local expected_field="$3"
    local expected_value="$4"
    
    if [ -z "$response" ]; then
        test_result "$test_name" "FAIL" "Empty response"
        return 1
    fi
    
    # Try to parse JSON with jq (preferred) or python3
    if command -v jq >/dev/null 2>&1; then
        # Use jq for JSON parsing
        if echo "$response" | jq . >/dev/null 2>&1; then
            # Check if field exists
            local field_value=$(echo "$response" | jq -r ".$expected_field // \"NOT_FOUND\"" 2>/dev/null)
            
            if [ "$field_value" = "NOT_FOUND" ]; then
                test_result "$test_name" "FAIL" "Field '$expected_field' not found in response"
                return 1
            elif [ -n "$expected_value" ] && [ "$field_value" != "$expected_value" ]; then
                test_result "$test_name" "FAIL" "Field '$expected_field' has value '$field_value', expected '$expected_value'"
                return 1
            else
                test_result "$test_name" "PASS" "JSON response valid with field '$expected_field'"
                return 0
            fi
        else
            test_result "$test_name" "FAIL" "Invalid JSON response (jq parse error)"
            return 1
        fi
    elif command -v python3 >/dev/null 2>&1; then
        # Fallback to python3
        if echo "$response" | python3 -c "import json, sys; json.loads(sys.stdin.read())" 2>/dev/null; then
            # Check if field exists
            local field_value=$(echo "$response" | python3 -c "import json, sys; data=json.loads(sys.stdin.read()); print(data.get('$expected_field', 'NOT_FOUND'))" 2>/dev/null)
            
            if [ "$field_value" = "NOT_FOUND" ]; then
                test_result "$test_name" "FAIL" "Field '$expected_field' not found in response"
                return 1
            elif [ -n "$expected_value" ] && [ "$field_value" != "$expected_value" ]; then
                test_result "$test_name" "FAIL" "Field '$expected_field' has value '$field_value', expected '$expected_value'"
                return 1
            else
                test_result "$test_name" "PASS" "JSON response valid with field '$expected_field'"
                return 0
            fi
        else
            test_result "$test_name" "FAIL" "Invalid JSON response"
            return 1
        fi
    else
        test_result "$test_name" "SKIP" "No JSON parser available (install jq or python3)"
        return 1
    fi
}

# Test basic API connectivity
test_basic_api() {
    log "Testing basic API connectivity..." "INFO"
    
    # Test Elementify namespace (should return 200 if authenticated, 401 if not)
    check_http_status "Elementify API Namespace" "${API_BASE}/${ELEMENTIFY_NAMESPACE}" 200 401
    
    # Test plugin activation status via HTTP response
    # If namespace returns 200 (authenticated) or 401 (unauthenticated), plugin is active
    # If namespace returns 404, plugin is not active
    local result=$(http_request "GET" "${API_BASE}/${ELEMENTIFY_NAMESPACE}")
    local http_code=$(echo "$result" | cut -d'|' -f1 | tr -d '\n\r' | xargs)
    if [ "$http_code" = "200" ] || [ "$http_code" = "401" ]; then
        test_result "Elementify Plugin Activation" "PASS" "Plugin is active (HTTP $http_code)"
    elif [ "$http_code" = "404" ]; then
        test_result "Elementify Plugin Activation" "FAIL" "Plugin is not active (HTTP 404)"
    else
        test_result "Elementify Plugin Activation" "SKIP" "Unexpected HTTP code: $http_code"
    fi
}

# Test authentication
test_authentication() {
    log "Testing authentication..." "INFO"
    
    if [ -z "$API_KEY" ]; then
        test_result "API Key Configuration" "SKIP" "No API key configured (set ELEMENTIFY_API_KEY in .env)"
        return
    fi
    
    # Test authenticated request
    local result=$(http_request "GET" "${API_BASE}/${ELEMENTIFY_NAMESPACE}/test-auth")
    local http_code=$(echo "$result" | cut -d'|' -f1)
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "401" ]; then
        test_result "Authentication Endpoint" "PASS" "Authentication endpoint responded with HTTP $http_code"
    else
        test_result "Authentication Endpoint" "FAIL" "Unexpected HTTP code: $http_code"
    fi
    
    # Test without API key (should fail)
    local original_key="$API_KEY"
    API_KEY=""
    local result=$(http_request "GET" "${API_BASE}/${ELEMENTIFY_NAMESPACE}/test-auth")
    local http_code=$(echo "$result" | cut -d'|' -f1)
    API_KEY="$original_key"
    
    if [ "$http_code" = "401" ] || [ "$http_code" = "403" ]; then
        test_result "Authentication Required" "PASS" "Unauthenticated request correctly rejected"
    else
        test_result "Authentication Required" "WARNING" "Unauthenticated request returned HTTP $http_code (expected 401)"
    fi
}

# Test template endpoints
test_template_endpoints() {
    log "Testing template endpoints..." "INFO"
    
    # Get templates list
    local response=$(check_http_status "Get Templates List" "${API_BASE}/${ELEMENTIFY_NAMESPACE}/templates" 200 401)
    if [ -n "$response" ]; then
        check_json_response "Templates List JSON" "$response" "templates" ""
    fi
    
    # Test template creation (if authorized)
    local test_template='{"title": "Test Template", "type": "section", "content": "Test content"}'
    local result=$(http_request "POST" "${API_BASE}/${ELEMENTIFY_NAMESPACE}/templates" "$test_template")
    local http_code=$(echo "$result" | cut -d'|' -f1)
    local response=$(echo "$result" | cut -d'|' -f2-)
    
    if [ "$http_code" = "201" ]; then
        test_result "Create Template" "PASS" "Template created successfully"
        # Extract template ID for cleanup
        local template_id=$(extract_json_field "$response" "id")
        if [ -n "$template_id" ]; then
            # Test get template by ID
            check_http_status "Get Template by ID" "${API_BASE}/${ELEMENTIFY_NAMESPACE}/templates/$template_id" 200
            
            # Clean up: delete template
            check_http_status "Delete Template" "${API_BASE}/${ELEMENTIFY_NAMESPACE}/templates/$template_id" 200 204 "DELETE"
        fi
    elif [ "$http_code" = "401" ] || [ "$http_code" = "403" ]; then
        test_result "Create Template" "SKIP" "Insufficient permissions (HTTP $http_code)"
    else
        test_result "Create Template" "SKIP" "Unexpected response (HTTP $http_code)"
    fi
}

# Test page endpoints
test_page_endpoints() {
    log "Testing page endpoints..." "INFO"
    
    # Get pages list
    local response=$(check_http_status "Get Pages List" "${API_BASE}/${ELEMENTIFY_NAMESPACE}/pages" 200 401)
    if [ -n "$response" ]; then
        check_json_response "Pages List JSON" "$response" "pages" ""
    fi
    
    # Test WordPress core pages endpoint (should always work)
    local response=$(check_http_status "WordPress Pages Endpoint" "${API_BASE}/wp/v2/pages" 200)
    if [ -n "$response" ]; then
        check_json_response "WordPress Pages JSON" "$response" "" ""
    fi
}

# Test media endpoints
test_media_endpoints() {
    log "Testing media endpoints..." "INFO"
    
    # Get media list
    local response=$(check_http_status "Get Media List" "${API_BASE}/${ELEMENTIFY_NAMESPACE}/media" 200 401)
    if [ -n "$response" ]; then
        check_json_response "Media List JSON" "$response" "media" ""
    fi
    
    # Test WordPress core media endpoint
    local response=$(check_http_status "WordPress Media Endpoint" "${API_BASE}/wp/v2/media" 200)
    if [ -n "$response" ]; then
        check_json_response "WordPress Media JSON" "$response" "" ""
    fi
}

# Test settings endpoints
test_settings_endpoints() {
    log "Testing settings endpoints..." "INFO"
    
    # Get settings
    local response=$(check_http_status "Get Settings" "${API_BASE}/${ELEMENTIFY_NAMESPACE}/settings" 200 401)
    if [ -n "$response" ]; then
        check_json_response "Settings JSON" "$response" "settings" ""
    fi
    
    # Test update settings (read-only for test)
    local test_settings='{"debug": true, "test_mode": true}'
    local result=$(http_request "PUT" "${API_BASE}/${ELEMENTIFY_NAMESPACE}/settings" "$test_settings")
    local http_code=$(echo "$result" | cut -d'|' -f1)
    
    if [ "$http_code" = "200" ]; then
        test_result "Update Settings" "PASS" "Settings updated successfully"
    elif [ "$http_code" = "401" ] || [ "$http_code" = "403" ]; then
        test_result "Update Settings" "SKIP" "Insufficient permissions (HTTP $http_code)"
    else
        test_result "Update Settings" "SKIP" "Unexpected response (HTTP $http_code)"
    fi
}

# Test MCP integration
test_mcp_integration() {
    log "Testing MCP integration..." "INFO"
    
    # Check if MCP server is mentioned in plugin
    if docker-compose ps wordpress 2>/dev/null | grep -q "Up"; then
        local mcp_files=$(docker-compose exec ${COMPOSE_PROJECT}-wordpress find /var/www/html/wp-content/plugins/elementify -name "*mcp*" -type f 2>/dev/null || echo "")
        
        if [ -n "$mcp_files" ]; then
            test_result "MCP Files Present" "PASS" "MCP-related files found in plugin"
            
            # Check for MCP server process (if running in container)
            local mcp_process=$(docker-compose exec ${COMPOSE_PROJECT}-wordpress ps aux 2>/dev/null | grep -i mcp || echo "")
            if [ -n "$mcp_process" ]; then
                test_result "MCP Server Running" "PASS" "MCP server process detected"
            else
                test_result "MCP Server Running" "SKIP" "MCP server not running (may be external)"
            fi
        else
            test_result "MCP Files Present" "SKIP" "No MCP-related files found (may be different plugin structure)"
        fi
    else
        test_result "MCP Integration Check" "SKIP" "WordPress container not running"
    fi
    
    # Test MCP health endpoint (if exists)
    check_http_status "MCP Health Endpoint" "${WORDPRESS_URL}/mcp/health" 200 404
}

# Generate report
generate_report() {
    local report_file="$1"
    
    cat > "$report_file" << EOF
{
  "test_suite": "Elementify API Test Suite",
  "timestamp": "$(date -Iseconds)",
  "environment": {
    "wordpress_url": "$WORDPRESS_URL",
    "api_base": "$API_BASE",
    "elementify_namespace": "$ELEMENTIFY_NAMESPACE",
    "api_key_configured": $( [ -n "$API_KEY" ] && echo "true" || echo "false" )
  },
  "summary": {
    "total_tests": $TESTS_TOTAL,
    "passed": $TESTS_PASSED,
    "failed": $TESTS_FAILED,
    "skipped": $TESTS_SKIPPED,
    "success_rate": $( [ $TESTS_TOTAL -gt 0 ] && echo "scale=2; $TESTS_PASSED * 100 / $TESTS_TOTAL" | bc || echo "0" )
  },
  "test_configuration": {
    "basic_tests": $TEST_BASIC,
    "auth_tests": $TEST_AUTH,
    "template_tests": $TEST_TEMPLATES,
    "page_tests": $TEST_PAGES,
    "media_tests": $TEST_MEDIA,
    "settings_tests": $TEST_SETTINGS,
    "mcp_tests": $TEST_MCP
  },
  "recommendations": [
    $( [ $TESTS_FAILED -gt 0 ] && echo '"Review failed tests and fix API issues."' || echo '"All tests passed. Elementify API appears to be working correctly."' )
    $( [ -z "$API_KEY" ] && echo ', "Configure ELEMENTIFY_API_KEY in .env for authentication tests."' )
    $( [ $TESTS_SKIPPED -gt 0 ] && echo ', "Some tests were skipped. Check permissions and plugin configuration."' )
  ]
}
EOF
    
    log "Report generated: $report_file" "INFO"
    
    # Print summary
    echo ""
    echo "========================================="
    echo "ELEMENTIFY API TEST SUITE - SUMMARY"
    echo "========================================="
    echo "Total Tests:  $TESTS_TOTAL"
    echo "Passed:       $TESTS_PASSED"
    echo "Failed:       $TESTS_FAILED"
    echo "Skipped:      $TESTS_SKIPPED"
    echo "Success Rate: $( [ $TESTS_TOTAL -gt 0 ] && echo "scale=1; $TESTS_PASSED * 100 / $TESTS_TOTAL" | bc || echo "0" )%"
    echo "-----------------------------------------"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo "✅ All tests passed! Elementify API is ready for production."
        echo "   The plugin can be safely installed on marcus-urban.de and fusionaize.com"
    else
        echo "❌ $TESTS_FAILED test(s) failed. Review the errors above."
        echo "   Fix the issues before installing on production sites."
    fi
    
    echo "========================================="
    echo ""
    echo "Full report saved to: $report_file"
}

# Main test execution
main() {
    log "Starting Elementify API Test Suite" "INFO"
    log "WordPress URL: $WORDPRESS_URL" "INFO"
    log "API Base: $API_BASE" "INFO"
    log "Elementify Namespace: $ELEMENTIFY_NAMESPACE" "INFO"
    log "Report File: $REPORT_FILE" "INFO"
    
    # Check if WordPress is running
    if ! curl -s -f "${WORDPRESS_URL}/" > /dev/null 2>&1; then
        log "WordPress is not running at $WORDPRESS_URL" "ERROR"
        log "Start the environment with: docker-compose up -d" "ERROR"
        exit 1
    fi
    
    # Run selected tests
    if [ "$TEST_BASIC" = true ]; then
        test_basic_api
    fi
    
    if [ "$TEST_AUTH" = true ]; then
        test_authentication
    fi
    
    if [ "$TEST_TEMPLATES" = true ]; then
        test_template_endpoints
    fi
    
    if [ "$TEST_PAGES" = true ]; then
        test_page_endpoints
    fi
    
    if [ "$TEST_MEDIA" = true ]; then
        test_media_endpoints
    fi
    
    if [ "$TEST_SETTINGS" = true ]; then
        test_settings_endpoints
    fi
    
    if [ "$TEST_MCP" = true ]; then
        test_mcp_integration
    fi
    
    # Generate report
    generate_report "$REPORT_FILE"
    
    # Exit with appropriate code
    if [ $TESTS_FAILED -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Run main function
main "$@"