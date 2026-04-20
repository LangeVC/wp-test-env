# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial public release preparation
- WordPress health check test script
- Generic plugin testing framework examples
- Agent-native badge and AI integration documentation
- Internal Elementify testing procedures documentation

### Changed
- Updated README to generic plugin testing framework
- Modified .gitignore to exclude Elementify-specific files
- Updated CI workflow to run generic health checks
- Converted Elementify-specific documentation to generic patterns

### Fixed
- Improved test script handling of HTTP 401/403 responses
- Fixed WordPress admin health check to accept 301 redirects

## [1.0.0] - 2025-04-20

### Added
- First public release of WordPress Testing Environment
- Complete Docker-based testing stack (WordPress, MySQL, phpMyAdmin, MailHog)
- Plugin installation and activation testing framework
- REST API testing utilities with example scripts
- Automated CI/CD workflow with GitHub Actions
- Comprehensive documentation (README, CONTRIBUTING, SECURITY, CODE_OF_CONDUCT)
- Automated update system for WordPress and Docker components
- Performance benchmarking and monitoring tools
- Security best practices and isolation guidelines

### Features
- Production-grade WordPress 6.5+ with full debugging
- MySQL 8.0 with health checks and persistence
- phpMyAdmin for database management
- MailHog for email testing and debugging
- WP-CLI for command-line management
- Volume mounts for easy plugin installation
- Hot-reload for plugins and themes
- Multiple WordPress instances support
- Customizable environment variables
- Production/Staging/Development modes
- Automated backup and restore
- Agent-native design for AI integration
- REST API-first architecture for agent access

### Security
- Isolated Docker network configuration
- Secure default credentials (change in production)
- Regular automated security updates
- No external database connections by default
- Local-only access configuration

---

## Release Notes Format

Each version should include:

### Added
- New features, functionality, or components

### Changed
- Changes to existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Security-related changes

## Versioning Policy

- **MAJOR** version (X.0.0): Incompatible API changes
- **MINOR** version (0.X.0): New functionality (backward compatible)  
- **PATCH** version (0.0.X): Bug fixes (backward compatible)