# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Nothing yet

### Changed
- Nothing yet

### Fixed
- Nothing yet

## [2.0.0] - 2026-05-04

### Added
- **Declarative Plugin Management** — `config/plugins.yaml` with support for wp.org, local, and URL plugin sources
- **Bundle System** — Premium plugin bundles with ordered installation and license key injection
- **One-Click Setup** — `scripts/setup.sh` handles Docker, WordPress, plugins, and bundles in one command
- **Docker Config Structure** — `docker/config/` with custom php.ini and mysql-init mounts
- **Plugin Configuration** — `PLUGINS_CONFIG` env var for pointing to custom plugin YAML

### Changed
- **Removed all Elementify-specific artifacts** — test scripts, API key generators, CI workflow, internal docs
- **Removed Elementor Pro Activator plugin** — replaced by declarative bundle system in `config/plugins.yaml`
- **Cleaned plugin directory** — only free dev tools (Query Monitor, Debug Bar, User Switching, WP Importer) committed
- **Updated docker-compose.yml** — added custom php.ini mount, mysql-init mount, scripts mount on wp-cli
- **Fixed init-test-environment.sh** — corrected docker-compose.yml path
- **Fixed install-plugin.sh** — corrected docker-compose.yml path references
- **Updated .gitignore** — explicit allow-list for committed plugin ZIPs
- **Updated .env.example** — sensible defaults included, no empty fields
- **Updated README.md** — removed 220-line Elementify section, added plugin management and bundle docs
- **Fixed SECURITY.md and CODE_OF_CONDUCT.md** — replaced placeholder emails

### Removed
- `_internal/` — Elementify bridge analysis and testing procedures
- `reports/` — Elementify test run reports
- `.elementify-api-key` — real API key file (security risk)
- `generate-api-key.php`, `generate-api-key-v2.php` — Elementify API key generators
- `scripts/setup-api-key.sh`, `scripts/setup-elementify-for-ci.sh`, `scripts/setup-elementify-api-key.php`, `scripts/generate-correct-key.php` — Elementify-specific scripts
- `tests/test-elementify-api.sh`, `tests/test-elementify-comprehensive.sh`, etc. — Elementify test suites
- `.github/workflows/ci-enhanced.yml` — Elementify-specific CI
- `docker-compose.yml.backup` — redundant backup file
- All extracted plugin directories and premium plugin ZIPs from `plugins/`
- `elementify-testing-feedback.md` — testing notes

### Security
- Removed `.elementify-api-key` file containing real API key
- Removed Elementor Pro Activator plugin (intercepted WordPress HTTP requests)
- Fixed placeholder emails in SECURITY.md and CODE_OF_CONDUCT.md

## [1.1.0] - 2025-04-20

### Added
- **Elementify API Testing Suite** - Comprehensive test framework for Elementify plugin REST API
- **API Key Authentication System** - Automated API key generation with correct capability structure
- **Enhanced CI/CD Pipeline** - GitHub Actions workflow with Elementify API testing integration
- **Comprehensive Test Scripts** - `test-elementify-comprehensive.sh` with detailed test coverage
- **Advanced Test Coverage** - 70+ Elementify API endpoints tested with automatic bug detection
- **API Key Generation Scripts** - PHP scripts for correct API key structure and governance settings
- **Capabilities Management** - Full support for Elementify's 46 capabilities and wildcard handling
- **GitHub Actions Environment** - Automated API key generation and testing in CI pipeline

### Changed
- **Updated CI Workflow** - Replaced basic `ci.yml` with enhanced `ci-enhanced.yml` workflow
- **Improved Test Scripts** - Enhanced error handling, statistics, and automatic skipping of buggy endpoints
- **Documentation Updates** - Added comprehensive Elementify testing guide to README
- **Security Enhancements** - Explicit capability lists instead of wildcards for better security
- **Test Structure** - Reorganized test scripts for better maintainability and reporting

### Fixed
- **API Key Structure** - Fixed incorrect key structure (is_active vs enabled, label vs name, capabilities format)
- **Governance Settings** - Fixed governance option to use explicit capability lists
- **Test Error Handling** - Improved handling of plugin bugs (AddonRegistry abstract class errors)
- **Authentication Issues** - Resolved API key authentication failures for Elementify endpoints
- **Capability Mismatches** - Fixed capability list to include all 46 Elementify capabilities
- **ISO Date Format** - Corrected created_at timestamp format in API key generation

### Security
- **Explicit Capabilities** - Replaced `["*"]` wildcard with explicit capability lists for API keys and governance
- **API Key Validation** - Enhanced validation of API key structure and permissions
- **Secure Defaults** - Improved default security settings for Elementify plugin testing

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