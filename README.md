# 🧪 WordPress Testing Environment

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)
[![Version](https://img.shields.io/badge/Version-2.0.0-blue.svg)](https://github.com/LangeVC/wp-testing-env/releases)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)
[![WordPress](https://img.shields.io/badge/WordPress-6.5+-blue.svg)](https://wordpress.org/)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen.svg)](https://github.com/LangeVC/wp-testing-env)
[![Agent-Native](https://img.shields.io/badge/Agent--Native-✓-green.svg)](https://github.com/LangeVC/wp-testing-env)

> Professional Docker-based WordPress testing environment for plugin development, quality assurance, automated testing workflows, and AI agent integration.

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/LangeVC/wp-testing-env.git
cd wp-testing-env

# Copy environment configuration
cp .env.example .env

# One-click setup
./scripts/setup.sh
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
│   ├── setup.sh                 # One-click environment setup
│   ├── install-plugin.sh        # Plugin installer
│   ├── setup-wordpress-fixed.sh # WordPress installation
│   └── init-test-environment.sh # Environment initialization
│
├── config/                      # Configuration files
│   ├── plugins.yaml             # Declarative plugin management
│   ├── php.ini                  # Custom PHP configuration
│   └── update-config.yaml       # Update automation config
│
├── docker/                      # Docker configuration
│   └── config/                  # Container configs (php.ini, mysql-init)
│
├── plugins/                     # WordPress plugins
│   ├── README.md                # Plugin guidelines
│   └── *.zip                    # Plugin archives
│
├── vendor-assets/               # Premium plugins & assets (gitignored)
├── themes/                      # WordPress themes
├── uploads/                     # Media uploads
└── tests/                       # Test scripts
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

## 🛠️ Usage

### Plugin Management

Plugins are declared in `config/plugins.yaml` and installed automatically by `scripts/setup.sh`:

```yaml
# config/plugins.yaml
plugins:
  - slug: woocommerce
    name: WooCommerce
    source: wordpress.org
  - slug: my-premium-plugin
    name: My Premium Plugin
    source: local
    zip_path: vendor-assets/my-premium-plugin.zip
```

Three source types are supported:

| Source | Description |
|--------|-------------|
| `wordpress.org` | Pulled from the WordPress.org plugin directory |
| `local` | ZIP file placed in `vendor-assets/` (gitignored) |
| `url` | Downloaded from a URL at install time |

For premium plugins that need a license bypass or activator, use **bundles**:

```yaml
bundles:
  elementor-pro-bundle:
    description: "Elementor Pro"
    plugins:
      - slug: elementor
        source: wordpress.org
        install_order: 1
      - slug: elementor-pro
        source: local
        zip_path: vendor-assets/elementor-pro.zip
        install_order: 2
      - slug: elementor-pro-activator
        source: local
        zip_path: vendor-assets/elementor-pro-activator.zip
        install_order: 3
        license:
          key: "your-license-key"
          method: wp_option
```

### Installing Plugins Manually

```bash
# Install a plugin from ZIP file
./scripts/install-plugin.sh plugins/query-monitor.zip

# Install from wordpress.org via WP-CLI
docker compose run --rm wp-cli wp plugin install woocommerce --activate
```

### Testing Workflow

1. **Setup Environment:**
   ```bash
   ./scripts/setup.sh
   ```

2. **Install Test Plugin:**
   ```bash
   ./scripts/install-plugin.sh path/to/plugin.zip
   ```

3. **Run Automated Tests:**
   ```bash
   ./tests/test-wordpress-health.sh
   ./tests/test-plugin-activation.sh path/to/plugin.zip
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
git clone https://github.com/LangeVC/wp-testing-env.git

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

A successful test suite validates that your plugin is ready for production. Test completion indicates:
- ✅ Plugin correctly installed and activated
- ✅ REST API endpoints properly registered
- ✅ Authentication system functional (if applicable)
- ✅ Core functionality operational
- ✅ Error handling properly implemented

## 🔗 References

## 📄 License

This project is licensed under the **Apache License 2.0** — see the [LICENSE](LICENSE) file for details.

## 🔧 Creating a Customized Test Environment

This repository provides the base WordPress stack. For project-specific testing (e.g. a specific plugin, theme, or addon ecosystem), create an overlay by extending the configuration:

### 1. Custom Plugin Set

Copy `config/plugins.yaml` and add your plugins:

```yaml
# my-project-plugins.yaml
plugins:
  - slug: woocommerce
    name: WooCommerce
    source: wordpress.org
  - slug: my-plugin
    name: My Plugin
    source: local
    zip_path: vendor-assets/my-plugin.zip
```

Then point the setup script at it:

```bash
PLUGINS_CONFIG=config/my-project-plugins.yaml ./scripts/setup.sh
```

### 2. Premium Plugin Bundles

Use bundles in your plugin config for premium plugins that require a license bypass or activator:

```yaml
bundles:
  pro-bundle:
    description: "Premium plugin with activator"
    plugins:
      - slug: free-base
        source: wordpress.org
        install_order: 1
      - slug: pro-version
        source: local
        zip_path: vendor-assets/pro-version.zip
        install_order: 2
      - slug: pro-activator
        source: local
        zip_path: vendor-assets/pro-activator.zip
        install_order: 3
        license:
          key: "your-license-key"
          method: wp_option
```

Place premium ZIPs in `vendor-assets/` (gitignored — never committed).

### 3. Project-Specific Test Scripts

Add your test scripts to your project repo. Use the existing test helpers:

```bash
#!/bin/bash
source wp-testing-env/tests/test-helpers.sh

# Your project-specific tests here
check_wp_ready
check_plugin_active "my-plugin"
# ...
```

### 4. CI/CD Integration

Example GitHub Actions workflow calling the base setup:

```yaml
- name: Start test environment
  run: |
    cd wp-testing-env
    ./scripts/setup.sh
- name: Run project tests
  run: |
    cd my-project
    ./tests/run.sh
```

## 🙏 Acknowledgments

- WordPress community for excellent documentation
- Docker team for containerization technology
- All contributors who help improve this project

## 📞 Support

- 📖 **Documentation:** [GitHub Wiki](https://github.com/LangeVC/wp-testing-env/wiki)
- 🐛 **Issues:** [GitHub Issues](https://github.com/LangeVC/wp-testing-env/issues)
- 💬 **Discussion:** [GitHub Discussions](https://github.com/LangeVC/wp-testing-env/discussions)
- 🚀 **Features:** [GitHub Projects](https://github.com/LangeVC/wp-testing-env/projects)

---

**Maintained by [LangeVC](https://github.com/LangeVC) • [langevc.com](https://langevc.com)**