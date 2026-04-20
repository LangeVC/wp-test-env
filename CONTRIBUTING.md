# Contributing to WordPress Testing Environment

First off, thank you for considering contributing to the WordPress Testing Environment! It's people like you that make this project better for everyone.

## 🎯 Code of Conduct

By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md). Please read it before contributing.

## 🌟 How Can I Contribute?

### Reporting Bugs
Before creating bug reports, please check the [existing issues](https://github.com/typelicious/wp-testing-env/issues) to avoid duplicates.

**Great Bug Reports** should include:
- Clear, descriptive title
- Steps to reproduce the issue
- Expected vs. actual behavior
- Environment details (Docker version, OS, etc.)
- Relevant logs or screenshots

### Suggesting Enhancements
Enhancement suggestions are welcome! When suggesting an enhancement:

1. Use a clear, descriptive title
2. Provide a detailed description of the proposed feature
3. Explain why this enhancement would be useful
4. Include examples or mockups if applicable

### Pull Requests
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## 🏗️ Development Setup

### Prerequisites
- Docker and Docker Compose
- Git
- Basic understanding of WordPress

### Local Development
```bash
# Clone your fork
git clone https://github.com/your-username/wp-testing-env.git
cd wp-testing-env

# Set up environment
cp .env.example .env
docker-compose up -d

# Run tests
./scripts/test-all.sh
```

### Testing Your Changes
Before submitting a PR, ensure:
- [ ] All tests pass
- [ ] Docker containers build successfully
- [ ] Documentation is updated
- [ ] Code follows WordPress coding standards

## 📝 Coding Standards

### Docker Configuration
- Use environment variables for configuration
- Follow Docker best practices
- Include health checks for services
- Use specific image versions (not `latest`)

### Shell Scripts
- Use `#!/usr/bin/env bash` shebang
- Include error handling with `set -euo pipefail`
- Add meaningful comments
- Follow shellcheck guidelines

### Documentation
- Use Markdown formatting
- Include code examples
- Keep README.md updated
- Document new features

## 🧪 Testing Guidelines

### Test Categories
1. **Unit Tests**: Individual script functions
2. **Integration Tests**: Docker services working together
3. **System Tests**: Complete environment functionality
4. **Performance Tests**: Resource usage and speed

### Running Tests
```bash
# Run all tests
./scripts/test-all.sh

# Run specific test category
./tests/unit/run.sh
./tests/integration/run.sh
```

## 📚 Documentation

### Updating Documentation
- Update README.md for significant changes
- Add/update inline code comments
- Document environment variables
- Include examples for new features

### Doc Structure
```
docs/
├── ENVIRONMENT_SETUP.md
├── PLUGIN_TESTING.md
├── API_TESTING.md
└── PERFORMANCE_TESTING.md
```

## 🔍 Review Process

1. **Initial Review**: Maintainers review PR within 48 hours
2. **Feedback**: Comments and suggestions provided
3. **Revisions**: Contributor addresses feedback
4. **Merge**: PR merged after approval

### What We Look For
- ✅ Code quality and readability
- ✅ Test coverage
- ✅ Documentation updates
- ✅ No breaking changes
- ✅ Security considerations

## 🏷️ Versioning

We follow [Semantic Versioning](https://semver.org/):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

## 📦 Release Process

1. Update version in relevant files
2. Update CHANGELOG.md
3. Create release tag
4. Build and test release
5. Publish release notes

## ❓ Getting Help

- **Documentation**: Check the [README](README.md) first
- **Issues**: Search existing [issues](https://github.com/typelicious/wp-testing-env/issues)
- **Discussions**: Join [GitHub Discussions](https://github.com/typelicious/wp-testing-env/discussions)

## 🙏 Acknowledgments

Thank you for contributing! Your efforts help make this project better for the entire WordPress community.