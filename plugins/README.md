# WordPress Testing Environment — Plugins

This directory is volume-mounted into the WordPress container at
`/var/www/html/wp-content/plugins/`.

## How plugins are managed

Plugins are declared in `config/plugins.yaml`. The setup script
(`scripts/setup.sh`) reads this file and installs them via WP-CLI.

Three source types are supported:

| Source | Example | Notes |
|--------|---------|-------|
| `wordpress.org` | `query-monitor` | Pulled from WP.org via WP-CLI |
| `local` | `vendor-assets/my-plugin.zip` | ZIP placed in `vendor-assets/` |
| `url` | `https://example.com/plugin.zip` | Downloaded at install time |

## What's committed

Only ZIP files of **freely distributable** plugins belong in this repo.
Premium/proprietary plugins go into `vendor-assets/` (gitignored).

| Plugin | Type |
|--------|------|
| `debug-bar.zip` | Dev tool |
| `query-monitor.zip` | Dev tool |
| `user-switching.zip` | Dev tool |
| `wordpress-importer.zip` | Dev tool |

## Adding a plugin

1. Add the slug to `config/plugins.yaml` (for wp.org plugins)
2. Or place the ZIP in `vendor-assets/` and add a `local` entry
3. Run `./scripts/setup.sh` to install

## Bundles

Use `config/plugins.yaml` bundles for premium plugins that need an activator
or license key injection. See the bundled section of that file for examples.
