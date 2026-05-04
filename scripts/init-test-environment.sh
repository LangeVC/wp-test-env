#!/bin/bash

# WordPress Testing Environment Initialization
# Starts the Docker environment and sets up WordPress for testing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"
DOCKER_COMPOSE_FILE="${SCRIPT_DIR}/../docker-compose.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[STATUS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_status "Docker is running."
}

# Check if Docker Compose is available
check_docker_compose() {
    if ! command -v docker-compose > /dev/null 2>&1 && ! docker compose version > /dev/null 2>&1; then
        print_error "Docker Compose is not available."
        exit 1
    fi
    print_status "Docker Compose is available."
}

# Start Docker environment
start_environment() {
    print_status "Starting Docker environment..."
    
    # Use docker-compose if available, otherwise use docker compose
    if command -v docker-compose > /dev/null 2>&1; then
        COMPOSE_CMD="docker-compose -f $DOCKER_COMPOSE_FILE"
    else
        COMPOSE_CMD="docker compose -f $DOCKER_COMPOSE_FILE"
    fi
    
    # Start services
    $COMPOSE_CMD up -d
    
    # Check if services started successfully
    if [ $? -eq 0 ]; then
        print_status "Docker environment started successfully."
    else
        print_error "Failed to start Docker environment."
        exit 1
    fi
}

# Wait for services to be ready
wait_for_services() {
    print_status "Waiting for services to be ready..."
    
    # Wait for MySQL
    print_status "Waiting for MySQL..."
    MAX_ATTEMPTS=30
    ATTEMPT=1
    while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
        if docker-compose -f $DOCKER_COMPOSE_FILE exec -T mysql mysqladmin ping --silent; then
            print_status "MySQL is ready."
            break
        fi
        print_status "Attempt $ATTEMPT/$MAX_ATTEMPTS: MySQL not ready yet..."
        if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
            print_error "MySQL failed to start after $MAX_ATTEMPTS attempts."
            exit 1
        fi
        sleep 2
        ATTEMPT=$((ATTEMPT + 1))
    done
    
    # Wait for WordPress
    print_status "Waiting for WordPress..."
    ATTEMPT=1
    WORDPRESS_PORT=${WORDPRESS_PORT:-8082}
    while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
        if curl -s -f "http://localhost:$WORDPRESS_PORT" > /dev/null; then
            print_status "WordPress is ready."
            break
        fi
        print_status "Attempt $ATTEMPT/$MAX_ATTEMPTS: WordPress not ready yet..."
        if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
            print_warning "WordPress not responding, but continuing..."
        fi
        sleep 2
        ATTEMPT=$((ATTEMPT + 1))
    done
}

# Setup WordPress if not already installed
setup_wordpress() {
    print_status "Checking if WordPress is already installed..."
    
    # Check if WordPress is installed by looking for wp-config.php
    if docker-compose -f $DOCKER_COMPOSE_FILE exec -T wordpress test -f /var/www/html/wp-config.php; then
        print_status "WordPress is already installed."
        return 0
    fi
    
    print_status "WordPress not installed. Running setup..."
    
    # Run setup script
    if [ -f "${SCRIPT_DIR}/setup-wordpress.sh" ]; then
        bash "${SCRIPT_DIR}/setup-wordpress.sh"
    else
        print_warning "Setup script not found. Manual WordPress installation required."
        print_warning "Please visit http://localhost:${WORDPRESS_PORT:-8080} to install WordPress."
    fi
}

# Display service information
display_info() {
    print_status "=========================================="
    print_status "Testing Environment Ready!"
    print_status "=========================================="
    print_status "Services:"
    print_status "- WordPress:      http://localhost:${WORDPRESS_PORT:-8080}"
    print_status "- WordPress Admin: http://localhost:${WORDPRESS_PORT:-8080}/wp-admin"
    print_status "- phpMyAdmin:     http://localhost:${PHPMYADMIN_PORT:-8081}"
    print_status "- MailHog Web UI: http://localhost:${MAILHOG_WEB_PORT:-8025}"
    print_status "=========================================="
    print_status "Credentials:"
    print_status "- WordPress Admin User: ${WORDPRESS_ADMIN_USER:-admin}"
    print_status "- WordPress Admin Pass: ${WORDPRESS_ADMIN_PASSWORD:-admin}"
    print_status "- MySQL Root Password: ${MYSQL_ROOT_PASSWORD:-wordpress_root_password}"
    print_status "- MySQL Database: ${MYSQL_DATABASE:-wordpress_test}"
    print_status "=========================================="
    print_status "Useful Commands:"
    print_status "- View logs: docker-compose -f $DOCKER_COMPOSE_FILE logs -f"
    print_status "- Stop environment: docker-compose -f $DOCKER_COMPOSE_FILE down"
    print_status "- Restart environment: docker-compose -f $DOCKER_COMPOSE_FILE restart"
    print_status "- Install plugin: ./scripts/install-plugin.sh <plugin.zip>"
    print_status "=========================================="
}

# Main execution
main() {
    echo "=========================================="
    echo "WordPress Testing Environment Initialization"
    echo "=========================================="
    
    # Load environment variables
    if [ -f "$ENV_FILE" ]; then
        source "$ENV_FILE"
        print_status "Loaded environment from $ENV_FILE"
    else
        print_warning ".env file not found at $ENV_FILE, using defaults"
    fi
    
    # Run checks
    check_docker
    check_docker_compose
    
    # Start environment
    start_environment
    
    # Wait for services
    wait_for_services
    
    # Setup WordPress
    setup_wordpress
    
    # Display information
    display_info
    
    print_status "Initialization complete!"
}

# Run main function
main "$@"