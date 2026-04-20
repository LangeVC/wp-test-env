# WordPress Testing Environment - Plugins

This directory contains plugin ZIP files for the WordPress Testing Environment.

## Structure

Place plugin ZIP files in this directory. The following naming convention is recommended:

- `{plugin-name}.zip` - Plugin files (free or pro versions)
- `{plugin-name}-pro.zip` - Pro version plugins (if separate)

## Important Notes

⚠️ **DO NOT COMMIT PROPRIETARY PLUGINS TO GIT**

This directory is configured to ignore all plugin files except ZIP archives via `.gitignore`:
```gitignore
plugins/
!plugins/*.zip
!plugins/README.md
```

Only ZIP files and this README will be tracked in version control. Extracted plugin directories should remain in `.gitignore`.

## Recommended Plugins for Testing

For a comprehensive WordPress testing environment, consider these plugins:

### Essential Testing Plugins
- Query Monitor
- Debug Bar
- User Switching
- WordPress Importer

### Elementor Ecosystem
- Elementor (free)
- Elementor Pro (requires license)
- Essential Addons for Elementor
- Premium Addons for Elementor
- Happy Addons for Elementor

### Page Builders & Addons
- Brizy
- Beaver Builder
- Oxygen Builder
- Visual Composer/WPBakery

### Form Builders
- WPForms
- Gravity Forms
- Contact Form 7

### E-commerce
- WooCommerce
- Easy Digital Downloads

### Booking & Scheduling
- Amelia Booking
- Simply Schedule Appointments

### SEO & Analytics
- Yoast SEO
- Rank Math
- Google Site Kit

## Usage

The testing environment includes automated scripts to install plugins from ZIP files:

```bash
# Install a plugin from ZIP
./scripts/install-plugin.sh plugins/query-monitor.zip

# Install multiple plugins
./scripts/install-plugin.sh plugins/plugin1.zip plugins/plugin2.zip
```

## License & Copyright

Only include plugins you have the right to distribute. For proprietary plugins, ensure you have the appropriate licenses for testing purposes.