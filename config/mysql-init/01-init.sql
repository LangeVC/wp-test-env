-- MySQL initialization script for WordPress testing environment
-- This script runs when the MySQL container is first started

-- Create additional test databases if needed
CREATE DATABASE IF NOT EXISTS wordpress_test_backup;
CREATE DATABASE IF NOT EXISTS wordpress_test_migration;

-- Create additional user for testing
CREATE USER IF NOT EXISTS 'wordpress_test'@'%' IDENTIFIED BY 'wordpress_test_password';
GRANT ALL PRIVILEGES ON wordpress_test.* TO 'wordpress_test'@'%';
GRANT ALL PRIVILEGES ON wordpress_test_backup.* TO 'wordpress_test'@'%';
GRANT ALL PRIVILEGES ON wordpress_test_migration.* TO 'wordpress_test'@'%';
FLUSH PRIVILEGES;