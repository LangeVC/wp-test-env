#!/bin/bash

# Test Helper Functions for WordPress Plugin Testing

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TEST_PASS=0
TEST_FAIL=0
TEST_SKIP=0
TOTAL_TESTS=0

# Function to print test header
test_header() {
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}Test: $1${NC}"
    echo -e "${BLUE}==========================================${NC}"
}

# Function to print test result
test_result() {
    local test_name="$1"
    local status="$2"
    local message="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    case "$status" in
        "PASS")
            TEST_PASS=$((TEST_PASS + 1))
            echo -e "${GREEN}✓ PASS${NC}: $test_name - $message"
            ;;
        "FAIL")
            TEST_FAIL=$((TEST_FAIL + 1))
            echo -e "${RED}✗ FAIL${NC}: $test_name - $message"
            ;;
        "SKIP")
            TEST_SKIP=$((TEST_SKIP + 1))
            echo -e "${YELLOW}⚠ SKIP${NC}: $test_name - $message"
            ;;
        *)
            echo -e "${YELLOW}? UNKNOWN${NC}: $test_name - $message"
            ;;
    esac
}

# Function to print test summary
test_summary() {
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}Test Summary${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo -e "Total Tests:  $TOTAL_TESTS"
    echo -e "${GREEN}Passed:      $TEST_PASS${NC}"
    echo -e "${RED}Failed:      $TEST_FAIL${NC}"
    echo -e "${YELLOW}Skipped:     $TEST_SKIP${NC}"
    echo -e "${BLUE}==========================================${NC}"
    
    if [ $TEST_FAIL -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}$TEST_FAIL test(s) failed.${NC}"
        return 1
    fi
}

# Function to run a command and check exit code
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_exit="${3:-0}"
    
    echo -e "Running: $command"
    
    # Run the command
    eval "$command" > /tmp/test-output.log 2>&1
    local exit_code=$?
    
    if [ $exit_code -eq $expected_exit ]; then
        test_result "$test_name" "PASS" "Exit code $exit_code matches expected $expected_exit"
        return 0
    else
        echo -e "${YELLOW}Command output:${NC}"
        cat /tmp/test-output.log
        test_result "$test_name" "FAIL" "Exit code $exit_code does not match expected $expected_exit"
        return 1
    fi
}

# Function to check if a string exists in output
check_output() {
    local test_name="$1"
    local command="$2"
    local expected_string="$3"
    
    echo -e "Checking: $command for '$expected_string'"
    
    # Run the command
    local output
    output=$(eval "$command" 2>&1)
    local exit_code=$?
    
    if echo "$output" | grep -q "$expected_string"; then
        test_result "$test_name" "PASS" "Found '$expected_string' in output"
        return 0
    else
        echo -e "${YELLOW}Command output:${NC}"
        echo "$output"
        test_result "$test_name" "FAIL" "Did not find '$expected_string' in output"
        return 1
    fi
}

# Function to check if a URL returns expected HTTP status
check_http_status() {
    local test_name="$1"
    local url="$2"
    local expected_status="${3:-200}"
    local timeout="${4:-10}"
    
    echo -e "Checking HTTP: $url"
    
    # Use curl to check HTTP status
    local status_code
    status_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$timeout" "$url")
    
    if [ "$status_code" = "$expected_status" ]; then
        test_result "$test_name" "PASS" "HTTP $status_code matches expected $expected_status"
        return 0
    else
        test_result "$test_name" "FAIL" "HTTP $status_code does not match expected $expected_status"
        return 1
    fi
}

# Function to check if a WordPress plugin is active
check_plugin_active() {
    local plugin_slug="$1"
    
    # Use WP-CLI to check if plugin is active
    docker-compose -f ../docker/docker-compose.yml exec -T wp-cli wp plugin is-active "$plugin_slug" > /dev/null 2>&1
    return $?
}

# Function to check if a WordPress plugin is installed
check_plugin_installed() {
    local plugin_slug="$1"
    
    # Use WP-CLI to check if plugin is installed
    docker-compose -f ../docker/docker-compose.yml exec -T wp-cli wp plugin is-installed "$plugin_slug" > /dev/null 2>&1
    return $?
}

# Function to get WordPress debug log
get_debug_log() {
    docker-compose -f ../docker/docker-compose.yml exec -T wordpress cat /var/www/html/wp-content/debug.log 2>/dev/null || echo "No debug.log found"
}

# Function to check for PHP errors in debug log
check_php_errors() {
    local debug_log
    debug_log=$(get_debug_log)
    
    if echo "$debug_log" | grep -q -E "(Fatal error|Parse error|Warning|Notice)"; then
        echo -e "${YELLOW}PHP errors found in debug log:${NC}"
        echo "$debug_log" | grep -E "(Fatal error|Parse error|Warning|Notice)" | tail -10
        return 1
    fi
    return 0
}

# Function to wait for WordPress to be ready
wait_for_wordpress() {
    local max_attempts=30
    local attempt=1
    local wordpress_port=${WORDPRESS_PORT:-8080}
    
    echo -e "Waiting for WordPress to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "http://localhost:$wordpress_port" > /dev/null; then
            echo -e "${GREEN}WordPress is ready.${NC}"
            return 0
        fi
        echo -e "Attempt $attempt/$max_attempts: WordPress not ready yet..."
        if [ $attempt -eq $max_attempts ]; then
            echo -e "${RED}WordPress failed to start after $max_attempts attempts.${NC}"
            return 1
        fi
        sleep 2
        attempt=$((attempt + 1))
    done
}