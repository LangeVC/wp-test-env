#!/bin/bash
# WordPress Testing Environment Update Script
# Checks for updates and maintains environment freshness

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="${PROJECT_DIR}/config/update-config.yaml"
ENV_FILE="${PROJECT_DIR}/.env"
BACKUP_DIR="${PROJECT_DIR}/backups"
LOG_DIR="${PROJECT_DIR}/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Default values
FORCE_UPDATE=false
DRY_RUN=false
VERBOSE=false
LOG_FILE="${LOG_DIR}/update-${TIMESTAMP}.log"

# Load environment variables
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

COMPOSE_PROJECT="${COMPOSE_PROJECT_NAME:-wptesting}"

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [options]

Options:
  -h, --help          Show this help message
  -f, --force         Force update even if not needed
  -d, --dry-run       Check for updates but don't apply them
  -v, --verbose       Show detailed output
  -c, --config <file> Use custom config file (default: config/update-config.yaml)
  -l, --log <file>    Log to specified file (default: logs/update-<timestamp>.log)
  
Examples:
  $0                   # Check and apply updates
  $0 --dry-run        # Check for updates without applying
  $0 --force          # Force update all components
  $0 --verbose        # Show detailed update information
EOF
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -f|--force)
            FORCE_UPDATE=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -l|--log)
            LOG_FILE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$BACKUP_DIR"

# Logging function
log() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
    
    if [ "$VERBOSE" = true ] && [ "$level" != "DEBUG" ]; then
        echo "$message"
    fi
}

# Check if yq (YAML processor) is installed
check_yq() {
    if ! command -v yq &> /dev/null; then
        log "yq is not installed. Please install yq to process YAML config." "ERROR"
        log "Install with: brew install yq (macOS) or see https://github.com/mikefarah/yq" "ERROR"
        exit 1
    fi
}

# Read configuration from YAML
read_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log "Config file not found: $CONFIG_FILE" "WARNING"
        log "Using default configuration" "WARNING"
        return 1
    fi
    
    log "Reading configuration from: $CONFIG_FILE" "DEBUG"
    
    # Extract configuration values
    UPDATES_ENABLED=$(yq eval '.updates.enabled' "$CONFIG_FILE" 2>/dev/null || echo "true")
    CHECK_INTERVAL=$(yq eval '.updates.check_interval_hours' "$CONFIG_FILE" 2>/dev/null || echo "24")
    
    # Component updates
    UPDATE_WORDPRESS=$(yq eval '.updates.components.wordpress.enabled' "$CONFIG_FILE" 2>/dev/null || echo "true")
    UPDATE_DOCKER=$(yq eval '.updates.components.docker_images.enabled' "$CONFIG_FILE" 2>/dev/null || echo "true")
    UPDATE_PLUGINS=$(yq eval '.updates.components.plugins.enabled' "$CONFIG_FILE" 2>/dev/null || echo "false")
    UPDATE_THEMES=$(yq eval '.updates.components.themes.enabled' "$CONFIG_FILE" 2>/dev/null || echo "false")
    
    # Policies
    BACKUP_ENABLED=$(yq eval '.policies.backup_before_update' "$CONFIG_FILE" 2>/dev/null || echo "true")
    TEST_AFTER_UPDATE=$(yq eval '.policies.test_after_update' "$CONFIG_FILE" 2>/dev/null || echo "true")
    ROLLBACK_ENABLED=$(yq eval '.policies.rollback_on_failure' "$CONFIG_FILE" 2>/dev/null || echo "true")
    
    log "Configuration loaded" "DEBUG"
}

# Check if update is needed based on last check time
check_update_needed() {
    local last_check_file="${PROJECT_DIR}/.last_update_check"
    local current_time=$(date +%s)
    local last_check_time=0
    
    if [ -f "$last_check_file" ]; then
        last_check_time=$(cat "$last_check_file")
    fi
    
    local hours_since_last_check=$(( (current_time - last_check_time) / 3600 ))
    
    if [ "$FORCE_UPDATE" = true ] || [ "$hours_since_last_check" -ge "$CHECK_INTERVAL" ]; then
        echo "$current_time" > "$last_check_file"
        return 0  # Update needed
    else
        log "Last update check was $hours_since_last_check hours ago (interval: ${CHECK_INTERVAL}h)" "INFO"
        return 1  # Update not needed
    fi
}

# Create backup
create_backup() {
    if [ "$BACKUP_ENABLED" != "true" ]; then
        log "Backup disabled by configuration" "INFO"
        return 0
    fi
    
    local backup_name="backup_${TIMESTAMP}"
    local backup_path="${BACKUP_DIR}/${backup_name}"
    
    log "Creating backup: $backup_name" "INFO"
    
    mkdir -p "$backup_path"
    
    # Backup database
    log "Backing up database..." "DEBUG"
    docker-compose exec -T mysql mysqldump -u"${MYSQL_USER:-wordpress}" -p"${MYSQL_PASSWORD:-wordpress_password}" "${MYSQL_DATABASE:-wordpress_test}" > "${backup_path}/database.sql" 2>/dev/null || true
    
    # Backup uploads
    log "Backing up uploads..." "DEBUG"
    cp -r "${PROJECT_DIR}/uploads" "${backup_path}/" 2>/dev/null || true
    
    # Backup config
    log "Backing up configuration..." "DEBUG"
    cp "${PROJECT_DIR}/.env" "${backup_path}/" 2>/dev/null || true
    cp "${PROJECT_DIR}/docker-compose.yml" "${backup_path}/" 2>/dev/null || true
    
    log "Backup completed: $backup_path" "INFO"
}

# Check for Docker image updates
check_docker_updates() {
    if [ "$UPDATE_DOCKER" != "true" ]; then
        log "Docker image updates disabled by configuration" "INFO"
        return 0
    fi
    
    log "Checking for Docker image updates..." "INFO"
    
    local images=("wordpress:latest" "mysql:8.0" "phpmyadmin:latest" "mailhog/mailhog:latest" "wordpress:cli")
    local updates_available=false
    
    for image in "${images[@]}"; do
        log "Checking $image..." "DEBUG"
        
        # Get current image ID
        local current_id=$(docker images --format "{{.ID}}" "$image" 2>/dev/null | head -1)
        
        # Pull latest image info (without downloading)
        docker pull "$image" --quiet 2>/dev/null
        
        # Get new image ID
        local new_id=$(docker images --format "{{.ID}}" "$image" 2>/dev/null | head -1)
        
        if [ "$current_id" != "$new_id" ] && [ -n "$new_id" ]; then
            log "Update available for $image" "INFO"
            updates_available=true
            
            if [ "$DRY_RUN" = false ]; then
                log "Updating $image..." "INFO"
                docker pull "$image"
            fi
        else
            log "$image is up to date" "DEBUG"
        fi
    done
    
    if [ "$updates_available" = false ]; then
        log "All Docker images are up to date" "INFO"
    fi
}

# Check WordPress updates
check_wordpress_updates() {
    if [ "$UPDATE_WORDPRESS" != "true" ]; then
        log "WordPress updates disabled by configuration" "INFO"
        return 0
    fi
    
    log "Checking WordPress updates..." "INFO"
    
    # Check if WordPress is running
    if ! docker-compose ps wordpress | grep -q "Up"; then
        log "WordPress container is not running" "WARNING"
        return 1
    fi
    
    # Check WordPress version via WP-CLI
    local current_version=$(docker-compose run --rm ${COMPOSE_PROJECT}-wp-cli wp core version 2>/dev/null || echo "unknown")
    log "Current WordPress version: $current_version" "INFO"
    
    # Check for updates
    local update_check=$(docker-compose run --rm ${COMPOSE_PROJECT}-wp-cli wp core check-update --format=json 2>/dev/null || echo "[]")
    
    if echo "$update_check" | grep -q "version"; then
        log "WordPress update available" "INFO"
        
        if [ "$DRY_RUN" = false ]; then
            log "Updating WordPress core..." "INFO"
            docker-compose run --rm ${COMPOSE_PROJECT}-wp-cli wp core update
            docker-compose run --rm ${COMPOSE_PROJECT}-wp-cli wp core update-db
        fi
    else
        log "WordPress is up to date" "INFO"
    fi
}

# Check plugin updates
check_plugin_updates() {
    if [ "$UPDATE_PLUGINS" != "true" ]; then
        log "Plugin updates disabled by configuration" "INFO"
        return 0
    fi
    
    log "Checking plugin updates..." "INFO"
    
    # Get plugin updates
    local plugin_updates=$(docker-compose run --rm ${COMPOSE_PROJECT}-wp-cli wp plugin list --update=available --format=json 2>/dev/null || echo "[]")
    
    if [ "$plugin_updates" != "[]" ]; then
        local update_count=$(echo "$plugin_updates" | grep -o '"update":"available"' | wc -l)
        log "$update_count plugin updates available" "INFO"
        
        if [ "$DRY_RUN" = false ]; then
            # Update plugins
            docker-compose run --rm ${COMPOSE_PROJECT}-wp-cli wp plugin update --all
        fi
    else
        log "All plugins are up to date" "INFO"
    fi
}

# Run post-update tests
run_post_update_tests() {
    if [ "$TEST_AFTER_UPDATE" != "true" ]; then
        log "Post-update tests disabled by configuration" "INFO"
        return 0
    fi
    
    log "Running post-update tests..." "INFO"
    
    # Test 1: WordPress health
    log "Testing WordPress health..." "DEBUG"
    if docker-compose run --rm ${COMPOSE_PROJECT}-wp-cli wp core verify-checksums 2>/dev/null; then
        log "WordPress health check: PASSED" "INFO"
    else
        log "WordPress health check: FAILED" "WARNING"
    fi
    
    # Test 2: Database connection
    log "Testing database connection..." "DEBUG"
    if docker-compose run --rm ${COMPOSE_PROJECT}-wp-cli wp db check 2>/dev/null; then
        log "Database connection: PASSED" "INFO"
    else
        log "Database connection: FAILED" "WARNING"
    fi
    
    # Test 3: REST API
    log "Testing REST API..." "DEBUG"
    local api_test=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8082/wp-json/ 2>/dev/null || echo "000")
    if [ "$api_test" = "200" ]; then
        log "REST API: PASSED (HTTP $api_test)" "INFO"
    else
        log "REST API: FAILED (HTTP $api_test)" "WARNING"
    fi
    
    log "Post-update tests completed" "INFO"
}

# Rollback on failure
rollback_if_needed() {
    if [ "$ROLLBACK_ENABLED" != "true" ]; then
        return 0
    fi
    
    # Check if WordPress is working
    local health_check=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8082/ 2>/dev/null || echo "000")
    
    if [ "$health_check" != "200" ] && [ "$health_check" != "000" ]; then
        log "WordPress health check failed (HTTP $health_check), attempting rollback..." "ERROR"
        
        # Find latest backup
        local latest_backup=$(ls -dt "${BACKUP_DIR}/backup_"* 2>/dev/null | head -1)
        
        if [ -n "$latest_backup" ]; then
            log "Rolling back to backup: $(basename "$latest_backup")" "INFO"
            
            # Restore database
            if [ -f "${latest_backup}/database.sql" ]; then
                log "Restoring database..." "DEBUG"
                docker-compose exec -T mysql mysql -u"${MYSQL_USER:-wordpress}" -p"${MYSQL_PASSWORD:-wordpress_password}" "${MYSQL_DATABASE:-wordpress_test}" < "${latest_backup}/database.sql" 2>/dev/null || true
            fi
            
            log "Rollback completed. Please check WordPress manually." "INFO"
        else
            log "No backup found for rollback" "ERROR"
        fi
    fi
}

# Clean up old backups
cleanup_old_backups() {
    local retention_days=$(yq eval '.backup.retention_days' "$CONFIG_FILE" 2>/dev/null || echo "7")
    
    log "Cleaning up backups older than $retention_days days..." "DEBUG"
    
    find "${BACKUP_DIR}" -name "backup_*" -type d -mtime +$retention_days 2>/dev/null | while read -r old_backup; do
        log "Removing old backup: $(basename "$old_backup")" "DEBUG"
        rm -rf "$old_backup"
    done
}

# Main update process
main() {
    log "Starting WordPress Testing Environment update process" "INFO"
    log "Timestamp: $TIMESTAMP" "DEBUG"
    log "Dry run: $DRY_RUN" "DEBUG"
    log "Force update: $FORCE_UPDATE" "DEBUG"
    
    # Check prerequisites
    check_yq
    read_config
    
    # Check if update is needed
    if [ "$UPDATES_ENABLED" != "true" ] && [ "$FORCE_UPDATE" != true ]; then
        log "Updates disabled by configuration" "INFO"
        exit 0
    fi
    
    if ! check_update_needed && [ "$FORCE_UPDATE" != true ]; then
        log "Update not needed at this time" "INFO"
        exit 0
    fi
    
    log "Update check passed, proceeding with update process" "INFO"
    
    # Create backup before updates
    create_backup
    
    # Check and apply updates
    if [ "$DRY_RUN" = true ]; then
        log "DRY RUN MODE: Checking for updates only" "INFO"
    fi
    
    check_docker_updates
    check_wordpress_updates
    check_plugin_updates
    
    # Run post-update tests
    if [ "$DRY_RUN" = false ]; then
        run_post_update_tests
        rollback_if_needed
    fi
    
    # Cleanup old backups
    cleanup_old_backups
    
    log "Update process completed successfully" "INFO"
    log "Log file: $LOG_FILE" "INFO"
    
    if [ "$DRY_RUN" = true ]; then
        log "DRY RUN COMPLETE: No changes were made" "INFO"
    fi
}

# Run main function
main "$@"