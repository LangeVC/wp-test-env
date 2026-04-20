# 🧪 WordPress Testing Environment

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/Version-1.1.0-blue.svg)](https://github.com/typelicious/wp-testing-env/releases)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)
[![WordPress](https://img.shields.io/badge/WordPress-6.5+-blue.svg)](https://wordpress.org/)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen.svg)](https://github.com/typelicious/wp-testing-env)
[![Agent-Native](https://img.shields.io/badge/Agent--Native-✓-green.svg)](https://github.com/typelicious/wp-testing-env)

> Professional Docker-based WordPress testing environment for plugin development, quality assurance, automated testing workflows, and AI agent integration.

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/typelicious/wp-testing-env.git
cd wp-testing-env

# Copy environment configuration
cp .env.example .env

# Start the environment
docker-compose up -d

# Run WordPress setup
./scripts/setup-wordpress-fixed.sh
```

**Access Services:**
- 🌐 **WordPress:** http://localhost:8082
- 🗄️ **phpMyAdmin:** http://localhost:8083
- 📧 **MailHog:** http://localhost:8025
- 🔧 **WP-CLI:** `docker-compose exec wp-cli wp <command>`

## ✨ Features

### 🏗️ **Production-Grade Stack**
- **WordPress 6.5+** with full debugging enabled
- **MySQL 8.0** with health checks and persistence
- **phpMyAdmin** for database management
- **MailHog** for email testing and debugging
- **WP-CLI** for command-line management

### 🔍 **Advanced Debugging**
- Full error reporting and logging
- Query monitoring (with Query Monitor)
- Debug Bar integration
- Custom PHP configuration
- Development mode enabled

### ⚡ **Plugin Testing Workflow**
- Volume mounts for easy plugin installation
- Automated plugin installation scripts
- Standard and pro plugin support
- REST API testing endpoints
- Isolated testing environment

### 🔄 **Development Tools**
- Hot-reload for plugins and themes
- Multiple WordPress instances support
- Customizable environment variables
- Production/Staging/Development modes
- Automated backup and restore

### 🤖 **AI Agent Integration**
- **Agent-native design** - Optimized for AI agent interaction and automation
- **REST API-first architecture** - Complete WordPress API coverage for agent access
- **Structured test outputs** - Machine-readable test results and health checks
- **Automated workflow support** - Compatible with SkillWeave and faigate AI orchestration
- **Production validation** - Agent-verifiable deployment readiness checks

## 📁 Project Structure

```
wp-testing-env/
├── docker-compose.yml           # Docker Compose configuration
├── .env                         # Environment variables (gitignored)
├── .env.example                 # Environment template
├── README.md                    # This file
│
├── scripts/                     # Utility scripts
│   ├── setup-wordpress-fixed.sh # WordPress installation
│   ├── install-plugin.sh        # Plugin installer
│   └── init-test-environment.sh # Environment initialization
│
├── plugins/                     # WordPress plugins
│   ├── README.md                # Plugin guidelines
│   └── *.zip                    # Plugin archives (gitignored)
│
├── themes/                      # WordPress themes
├── uploads/                     # Media uploads
├── logs/                        # Application logs
└── reports/                     # Test reports
```

## 🔧 Configuration

### Environment Variables (.env)

```bash
# WordPress Configuration
WORDPRESS_PORT=8082
WORDPRESS_DEBUG=1
WORDPRESS_ADMIN_USER=admin
WORDPRESS_ADMIN_PASSWORD=admin

# Database Configuration  
MYSQL_ROOT_PASSWORD=secure_password
MYSQL_DATABASE=wordpress_test
MYSQL_USER=wordpress
MYSQL_PASSWORD=wordpress_password

# Service Ports
PHPMYADMIN_PORT=8083
MAILHOG_SMTP_PORT=1025
MAILHOG_WEB_PORT=8025
```

### Custom PHP Configuration

Create `config/php.ini` for custom PHP settings:

```ini
memory_limit = 256M
max_execution_time = 300
upload_max_filesize = 64M
post_max_size = 64M
```

## 🛠️ Usage Examples

### Installing Plugins

```bash
# Install a plugin from ZIP file
./scripts/install-plugin.sh plugins/query-monitor.zip

# Install multiple plugins
./scripts/install-plugin.sh plugins/plugin1.zip plugins/plugin2.zip
```

### Using WP-CLI

```bash
# List installed plugins
docker-compose exec wp-cli wp plugin list

# Activate a plugin
docker-compose exec wp-cli wp plugin activate elementor

# Create test content
docker-compose exec wp-cli wp post create \
  --post_title="Test Post" \
  --post_content="Test content" \
  --post_status=publish
```

### Testing Workflow

1. **Setup Environment:**
   ```bash
   ./scripts/init-test-environment.sh
   ```

2. **Install Test Plugin:**
   ```bash
   ./scripts/install-plugin.sh path/to/plugin.zip
   ```

3. **Run Automated Tests:**
   ```bash
   # Custom test scripts
   ./tests/activation-test.sh
   ./tests/rest-api-test.sh
   ```

4. **Generate Reports:**
   ```bash
   # Reports saved to ./reports/
   ```

## 📊 Testing Scenarios

### Plugin Activation Testing
- ✅ Activation hooks
- ✅ Database table creation
- ✅ Default settings initialization
- ✅ Compatibility checks

### REST API Testing  
- ✅ Endpoint registration
- ✅ Authentication/Authorization
- ✅ Data validation
- ✅ Error handling

### Performance Testing
- ✅ Database query optimization
- ✅ Memory usage monitoring
- ✅ Load time analysis
- ✅ Caching effectiveness

### Compatibility Testing
- ✅ WordPress version compatibility
- ✅ PHP version compatibility
- ✅ Plugin conflicts
- ✅ Theme compatibility

## 🔐 Security Best Practices

### Environment Security
- `.env` file gitignored by default
- Unique passwords for each environment
- Database root password protection
- Read-only volumes where possible

### WordPress Security
- Development mode enabled
- Debug information protected
- Secure database prefixes
- Limited external access

### Container Security
- Non-root user execution
- Resource limits
- Network isolation
- Regular image updates

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup

```bash
# Fork and clone
git clone https://github.com/typelicious/wp-testing-env.git

# Create feature branch
git checkout -b feature/awesome-feature

# Make changes and test
docker-compose up -d
./scripts/test-all.sh

# Commit and push
git commit -m "Add awesome feature"
git push origin feature/awesome-feature

# Create Pull Request
```

### Code Style
- Follow WordPress coding standards
- Use meaningful commit messages
- Include tests for new features
- Update documentation

## 📈 Performance Benchmarks

| Test Scenario | Average Time | Memory Usage | Notes |
|---------------|--------------|--------------|-------|
| Fresh Install | 45s | 128MB | Includes WordPress setup |
| Plugin Activation | 2-5s | Varies | Depends on plugin complexity |
| REST API Request | < 100ms | Minimal | Local network conditions |
| Database Query | < 50ms | Low | Optimized MySQL configuration |

## 🔌 Plugin Testing Framework

This environment includes a comprehensive testing framework for WordPress plugins with REST API endpoints. The framework provides tools for testing plugin installation, activation, API endpoints, and authentication.

### Plugin API Testing

The environment includes example test scripts that demonstrate how to test WordPress plugin REST APIs. To run the example tests:

```bash
# Run WordPress health check (verifies environment is running)
./tests/test-wordpress-health.sh

# Run plugin activation test (requires a plugin zip file)
./tests/test-plugin-activation.sh plugins/your-plugin.zip

# Review example test scripts for implementation patterns:
# - tests/test-plugin-api.sh.example - Complete API test template
# - tests/test-helpers.sh - Shared test utilities
```

### Authentication Requirements

Many plugins require authentication via API keys or tokens. The testing framework includes utilities for managing authentication:

```bash
# Example: Setting up API key authentication
echo "YOURPLUGIN_API_KEY=your_api_key_here" >> .env

# Example test script for API key validation is available at:
# scripts/setup-api-key.sh.example
```

### Test Coverage Framework

The testing framework supports comprehensive test coverage:

- **Basic API Connectivity**: Verify plugin namespace and activation
- **Authentication**: Test API key validation and security
- **CRUD Operations**: Test create, read, update, delete operations
- **Error Handling**: Test error responses and edge cases
- **Performance**: Test response times under load
- **Integration**: Test integration with WordPress core and other plugins

### Production Validation

A successful test suite validates that your plugin is ready for production deployment. Test completion indicates:

- ✅ Plugin correctly installed and activated
- ✅ REST API endpoints properly registered
- ✅ Authentication system functional (if applicable)
- ✅ Core functionality operational
- ✅ Error handling properly implemented
- ✅ Ready for production use

## 🔌 Elementify API Testing

This environment includes comprehensive testing support for the [Elementify](https://github.com/typelicious/elementify) WordPress automation toolkit. Elementify provides over 70 REST API endpoints for WordPress automation, and this testing environment includes specialized tools for API key authentication and endpoint validation.

### ⚡ Quick Start: Elementify Testing

```bash
# 1. Start the environment
docker-compose up -d

# 2. Install and activate Elementify plugin
./scripts/install-plugin.sh plugins/elementify.zip

# 3. Generate API key with correct capabilities
docker-compose exec wp-cli wp eval-file scripts/generate-api-key.php

# 4. Run comprehensive Elementify API tests
./tests/test-elementify-comprehensive.sh
```

### 🔑 API Key Authentication

Elementify requires API key authentication via the `X-Elementify-Key` header. The testing environment includes scripts to generate correctly structured API keys:

#### Correct API Key Structure
Elementify expects API keys with this specific structure:
```php
[
    'is_active' => true,           // NOT 'enabled'
    'label' => 'Test Key',         // NOT 'name'  
    'capabilities' => [...],       // Explicit list of 46 capabilities (not "*")
    'created_at' => '2025-04-20T10:30:00Z' // ISO 8601 format
]
```

#### Generating API Keys

**Using WP-CLI (Recommended):**
```bash
# Generate API key with all capabilities
docker-compose exec wp-cli wp eval-file scripts/generate-api-key.php

# Alternative: Generate using improved script
docker-compose exec wp-cli wp eval-file scripts/generate-api-key-v2.php
```

**Manual API Key Setup:**
```bash
# Check generated API key
docker-compose exec wp-cli wp option get elementify_mcp_api_keys --format=json

# Export API key as environment variable
export ELEMENTIFY_API_KEY=$(docker-compose exec wp-cli wp option get elementify_mcp_api_keys --format=json | jq -r '.[0].key')
echo "ELEMENTIFY_API_KEY=$ELEMENTIFY_API_KEY" >> .env
```

### 🧪 Test Scripts

The testing environment includes multiple test scripts for Elementify:

| Script | Purpose | Coverage |
|--------|---------|----------|
| `test-elementify-comprehensive.sh` | **Complete test suite** | 70+ endpoints, detailed statistics, bug detection |
| `test-elementify-api-improved.sh` | **Improved authentication** | Focus on API key validation and error handling |
| `test-elementify-api.sh` | **Basic API tests** | Core functionality and endpoint discovery |

#### Running Tests

```bash
# Run comprehensive tests (recommended)
./tests/test-elementify-comprehensive.sh

# Run with specific API key
ELEMENTIFY_API_KEY="your_key_here" ./tests/test-elementify-comprehensive.sh

# Run in CI mode (non-interactive)
CI=true ./tests/test-elementify-comprehensive.sh
```

### 🛡️ Capabilities Management

Elementify defines 46 capabilities for fine-grained access control. The testing environment handles capabilities correctly:

```bash
# View all Elementify capabilities
docker-compose exec wp-cli wp eval "print_r(Elementify\MCP\Auth\Capabilities::all());"

# Check configured capabilities
docker-compose exec wp-cli wp option get elementify_mcp_governance --format=json
```

**Important:** Elementify does **NOT** accept wildcard (`"*"`) capabilities. All 46 capabilities must be explicitly listed in both API keys and governance settings.

### 🔄 CI/CD Integration

The enhanced CI workflow (`ci-enhanced.yml`) automatically:

1. **Generates API Keys** - Creates correctly structured Elementify API keys
2. **Runs Comprehensive Tests** - Executes all Elementify test scripts
3. **Reports Results** - Provides detailed test statistics and coverage reports
4. **Detects Plugin Bugs** - Automatically skips known buggy endpoints (e.g., AddonRegistry errors)

#### GitHub Actions Usage

```yaml
# Example workflow step
- name: Test Elementify API
  run: |
    export ELEMENTIFY_API_KEY=$(scripts/generate-ci-key.sh)
    ./tests/test-elementify-comprehensive.sh
```

### 🐛 Known Issues & Workarounds

#### Plugin Bugs
Some Elementify endpoints may return 500 errors due to plugin bugs:

1. **AddonRegistry Abstract Class Error** - Endpoints `/elementify/v1/addons` and `/elementify/v1/site/assessment` may fail
2. **Workaround**: Test scripts automatically detect and skip these endpoints
3. **Fix**: Update Elementify plugin to resolve abstract class implementation

#### Authentication Issues
- **401 Unauthorized**: Verify API key structure matches exact format requirements
- **403 Forbidden**: Check capabilities list includes all 46 capabilities (not wildcard)
- **Missing Headers**: Ensure `X-Elementify-Key` header is sent with requests

### 📊 Test Coverage

The comprehensive test suite validates:

| Category | Endpoints Tested | Key Features |
|----------|------------------|--------------|
| **Templates** | 15+ endpoints | CRUD operations, versioning, search |
| **Site Management** | 10+ endpoints | Assessment, settings, recommendations |
| **Global Styles** | 5+ endpoints | Colors, typography, design tokens |
| **Pages & Content** | 20+ endpoints | Composition, workflow, approval |
| **Addons & Ecosystem** | 10+ endpoints | Detection, configuration, optimization |
| **Media & Assets** | 5+ endpoints | Upload, management, optimization |
| **WooCommerce** | 5+ endpoints | Products, orders, categories |

### 🚀 Advanced Testing

#### Testing Specific Endpoint Categories

```bash
# Test only template endpoints
./tests/test-elementify-comprehensive.sh --category templates

# Test with verbose output
./tests/test-elementify-comprehensive.sh --verbose

# Generate JSON test report
./tests/test-elementify-comprehensive.sh --json-report
```

#### Custom Test Configuration

Create `tests/elementify-test-config.json`:
```json
{
  "api_base": "http://localhost:8082/wp-json/elementify/v1",
  "api_key": "${ELEMENTIFY_API_KEY}",
  "skip_endpoints": ["/addons", "/site/assessment"],
  "timeout": 30,
  "retry_attempts": 3
}
```

### 🔧 Troubleshooting Elementify Tests

**API Key Not Working:**
```bash
# Verify key structure
docker-compose exec wp-cli wp option get elementify_mcp_api_keys --format=json | jq .

# Regenerate key
docker-compose exec wp-cli wp option delete elementify_mcp_api_keys
docker-compose exec wp-cli wp eval-file scripts/generate-api-key.php
```

**Endpoints Returning 500 Errors:**
```bash
# Check WordPress error log
docker-compose logs wordpress --tail 50

# Disable problematic endpoints in tests
export SKIP_BUGGY_ENDPOINTS=true
./tests/test-elementify-comprehensive.sh
```

**Capability Errors:**
```bash
# Reset governance settings
docker-compose exec wp-cli wp option update elementify_mcp_governance '{"capabilities": ["templates:read", "...all 46 capabilities..."]}'

# Verify capabilities
docker-compose exec wp-cli wp eval "echo json_encode(Elementify\MCP\Auth\Capabilities::all());"
```

### 📈 Test Results & Reporting

Test scripts generate detailed reports:

```bash
# View test statistics
cat reports/elementify-test-*.json | jq '.statistics'

# Check endpoint coverage  
cat reports/elementify-test-*.json | jq '.coverage'

# Identify failing endpoints
cat reports/elementify-test-*.json | jq '.failures[]'
```

Reports include:
- ✅ **Passed tests** with response times
- ❌ **Failed tests** with error details  
- ⚠️ **Skipped tests** (buggy endpoints)
- 📊 **Statistics** (success rate, average response time)
- 🎯 **Coverage** (percentage of endpoints tested)

---

### Troubleshooting Plugin Tests

**API Authentication Errors:**
```bash
# Check if your plugin's API keys are configured
docker exec wptesting-wordpress wp option get yourplugin_api_keys --allow-root

# Reset plugin activation
docker exec wptesting-wordpress wp plugin deactivate your-plugin --allow-root
docker exec wptesting-wordpress wp plugin activate your-plugin --allow-root
```

**REST Endpoint 404 Errors:**
```bash
# Verify REST API is working
curl http://localhost:8082/wp-json/

# Check your plugin's namespace
curl http://localhost:8082/wp-json/yourplugin/v1
```

**Plugin Activation Issues:**
```bash
# Check plugin status
docker exec wptesting-wordpress wp plugin status your-plugin --allow-root

# Review error logs
docker logs wptesting-wordpress --tail 50
```

## 🚨 Troubleshooting

### Common Issues

**Port Conflicts:**
```bash
# Check used ports
lsof -i :8082

# Update .env with different ports
WORDPRESS_PORT=8083
PHPMYADMIN_PORT=8084
```

**Permission Errors:**
```bash
# Reset Docker permissions
docker-compose down -v
sudo chown -R $USER:$USER .
docker-compose up -d
```

**Database Issues:**
```bash
# Check MySQL health
docker-compose exec mysql mysqladmin ping

# Reset database
docker-compose down -v
docker-compose up -d
```

### Debugging

View application logs:
```bash
# WordPress logs
docker-compose logs wordpress

# MySQL logs
docker-compose logs mysql

# All services
docker-compose logs -f
```

Check WordPress debug log:
```bash
docker-compose exec wordpress tail -f /var/www/html/wp-content/debug.log
```

## 🔄 Automatic Updates

Keep your testing environment up-to-date with the built-in update system.

### Update Configuration

The update system is configured via `config/update-config.yaml`:

```yaml
# Example configuration
updates:
  enabled: true
  check_interval_hours: 24
  components:
    wordpress:
      enabled: true
      track: "latest"
      auto_update: false
    docker_images:
      enabled: true
      auto_pull: false
```

### Using the Update Script

```bash
# Check for updates (dry run)
./scripts/update-environment.sh --dry-run

# Apply updates
./scripts/update-environment.sh

# Force update (ignore check interval)
./scripts/update-environment.sh --force

# Verbose output
./scripts/update-environment.sh --verbose
```

### Update Features

- **Smart Update Checks**: Only updates when needed based on configurable intervals
- **Component Selection**: Choose which components to update (WordPress, Docker images, plugins, themes)
- **Safety First**: Automatic backups before updates, rollback on failure
- **Post-Update Testing**: Verify environment health after updates
- **Configurable Policies**: Control backup retention, notifications, and update behavior

### Prerequisites

The update script requires `yq` for YAML processing:

```bash
# macOS
brew install yq

# Linux
sudo snap install yq

# Alternative: Install from GitHub
# See: https://github.com/mikefarah/yq
```

### Automated Updates (Cron)

For automated updates, add to crontab:

```bash
# Daily update check at 2 AM
0 2 * * * cd /path/to/wp-testing-env && ./scripts/update-environment.sh >> logs/updates.log 2>&1

# Weekly forced update on Sundays at 3 AM
0 3 * * 0 cd /path/to/wp-testing-env && ./scripts/update-environment.sh --force >> logs/updates.log 2>&1
```

## 📚 Documentation

- [Environment Setup Guide](docs/ENVIRONMENT_SETUP.md)
- [Plugin Testing Workflow](docs/PLUGIN_TESTING.md)
- [API Testing Guide](docs/API_TESTING.md)
- [Performance Testing](docs/PERFORMANCE_TESTING.md)

## 🏷️ Related Projects

- [**SkillWeave**](https://github.com/typelicious/SkillWeave) - AI-powered development workflow automation
- [**faigate**](https://github.com/fusionAIze/faigate) - FusionAIze Gateway for AI model orchestration
- [**Elementify**](https://github.com/typelicious/elementify) - WordPress automation toolkit

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- WordPress community for excellent documentation
- Docker team for containerization technology
- All contributors who help improve this project

## 📞 Support

- 📖 **Documentation:** [GitHub Wiki](https://github.com/typelicious/wp-testing-env/wiki)
- 🐛 **Issues:** [GitHub Issues](https://github.com/typelicious/wp-testing-env/issues)
- 💬 **Discussion:** [GitHub Discussions](https://github.com/typelicious/wp-testing-env/discussions)
- 🚀 **Features:** [GitHub Projects](https://github.com/typelicious/wp-testing-env/projects)

---

**Maintained by [typelicious](https://github.com/typelicious) • Part of the FusionAIze ecosystem**