#!/bin/bash
# WordPress Health Check Test
# Basic test to verify WordPress environment is running correctly

set -e

# Configuration
WORDPRESS_URL="${WORDPRESS_URL:-http://localhost:8082}"
API_BASE="${WORDPRESS_URL}/wp-json"
TIMEOUT="${TEST_TIMEOUT:-60}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0
TESTS_TOTAL=0

# Logging functions
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

test_result() {
    local test_name="$1"
    local status="$2"
    local message="$3"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    case "$status" in
        "PASS")
            echo -e "${GREEN}[PASS]${NC} $test_name: $message"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            ;;
        "FAIL")
            echo -e "${RED}[FAIL]${NC} $test_name: $message"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            ;;
        "SKIP")
            echo -e "${YELLOW}[SKIP]${NC} $test_name: $message"
            TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
            ;;
    esac
}

# Helper function to check HTTP status
check_http_status() {
    local url="$1"
    local expected_status="${2:-200}"
    local description="${3:-$url}"
    
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" -m "$TIMEOUT" "$url" 2>/dev/null || echo "000")
    
    if [ "$response" = "$expected_status" ]; then
        echo "$response"
        return 0
    else
        echo "$response"
        return 1
    fi
}

# Helper function to check JSON response
check_json_response() {
    local url="$1"
    local jq_filter="${2:-.}"
    local description="${3:-$url}"
    
    local response
    response=$(curl -s -f -m "$TIMEOUT" "$url" 2>/dev/null || echo "{}")
    
    if echo "$response" | jq -e "$jq_filter" >/dev/null 2>&1; then
        echo "$response"
        return 0
    else
        echo "$response"
        return 1
    fi
}

# Check if required tools are available
check_dependencies() {
    local missing=()
    
    for cmd in curl jq; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo "Missing required tools: ${missing[*]}"
        echo "Please install:"
        echo "  - curl: HTTP client"
        echo "  - jq: JSON processor"
        return 1
    fi
    return 0
}

# Main test function
run_health_check() {
    log "Starting WordPress health check..."
    log "WordPress URL: $WORDPRESS_URL"
    log "API Base: $API_BASE"
    
    # Test 1: WordPress homepage
    log "Testing WordPress homepage..."
    local home_status
    home_status=$(check_http_status "$WORDPRESS_URL" "200" "WordPress homepage")
    if [ "$home_status" = "200" ]; then
        test_result "WordPress Homepage" "PASS" "Homepage accessible (HTTP $home_status)"
    else
        test_result "WordPress Homepage" "FAIL" "Homepage not accessible (HTTP $home_status)"
    fi
    
    # Test 2: WordPress REST API root
    log "Testing WordPress REST API..."
    local api_status
    api_status=$(check_http_status "$API_BASE" "200" "WordPress REST API")
    if [ "$api_status" = "200" ]; then
        test_result "WordPress REST API" "PASS" "REST API accessible (HTTP $api_status)"
        
        # Test 2a: Check API returns valid JSON
        local api_json
        if api_json=$(check_json_response "$API_BASE" ".name" "WordPress REST API JSON"); then
            test_result "REST API JSON" "PASS" "Valid JSON response"
            
            # Extract site name from response
            local site_name
            site_name=$(echo "$api_json" | jq -r '.name // "Unknown"')
            log "Site name: $site_name"
        else
            test_result "REST API JSON" "FAIL" "Invalid JSON response"
        fi
    else
        test_result "WordPress REST API" "FAIL" "REST API not accessible (HTTP $api_status)"
    fi
    
    # Test 3: WordPress admin (should redirect to login)
    log "Testing WordPress admin area..."
    local admin_status
    admin_status=$(check_http_status "${WORDPRESS_URL}/wp-admin" "302" "WordPress admin")
    if [ "$admin_status" = "302" ] || [ "$admin_status" = "301" ] || [ "$admin_status" = "200" ]; then
        test_result "WordPress Admin" "PASS" "Admin area accessible (HTTP $admin_status)"
    else
        test_result "WordPress Admin" "FAIL" "Admin area not accessible (HTTP $admin_status)"
    fi
    
    # Test 4: Check WordPress version via REST API
    log "Checking WordPress version..."
    local version_json
    if version_json=$(check_json_response "${API_BASE}" ".version" "WordPress version API"); then
        local wp_version
        wp_version=$(echo "$version_json" | jq -r '.version // "Unknown"')
        test_result "WordPress Version" "PASS" "Version $wp_version detected"
    else
        # Try alternative location
        if version_json=$(check_json_response "${API_BASE}/" ".version" "WordPress version API"); then
            local wp_version
            wp_version=$(echo "$version_json" | jq -r '.version // "Unknown"')
            test_result "WordPress Version" "PASS" "Version $wp_version detected"
        else
            test_result "WordPress Version" "SKIP" "Could not retrieve version"
        fi
    fi
    
    # Test 5: Database connectivity (via health check endpoint if available)
    log "Checking database connectivity..."
    local health_status
    health_status=$(check_http_status "${API_BASE}/wp/v2" "200" "Database health")
    if [ "$health_status" = "200" ]; then
        # If we can access posts endpoint, database is likely working
        test_result "Database Connectivity" "PASS" "Database accessible via REST API"
    else
        test_result "Database Connectivity" "FAIL" "Database may not be accessible (HTTP $health_status)"
    fi
    
    # Summary
    echo ""
    echo "========================================"
    echo "WORDPRESS HEALTH CHECK SUMMARY"
    echo "========================================"
    echo "Total Tests:    $TESTS_TOTAL"
    echo -e "${GREEN}Passed:         $TESTS_PASSED${NC}"
    echo -e "${RED}Failed:         $TESTS_FAILED${NC}"
    echo -e "${YELLOW}Skipped:        $TESTS_SKIPPED${NC}"
    echo "========================================"
    
    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo -e "${GREEN}✓ All health checks passed! WordPress environment is healthy.${NC}"
        return 0
    else
        echo -e "${RED}✗ Some health checks failed. Review the errors above.${NC}"
        return 1
    fi
}

# Main execution
main() {
    # Check dependencies
    if ! check_dependencies; then
        echo "Dependency check failed. Exiting."
        exit 1
    fi
    
    # Run health check
    if ! run_health_check; then
        exit 1
    fi
}

# Run main function
main "$@"