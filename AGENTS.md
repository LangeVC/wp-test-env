# wp-test-env — Agents Guide

**Audience:** any AI coding agent (Claude Code, Cursor, OpenCode, etc.) and any human dev who lands here looking for "how do I run WordPress tests for my plugin/theme."

**TL;DR:** This is a **template**. It is not the place where your project lives. You consume it from your own project repository as an overlay. Never fork this repo to add project-specific plugins/themes/configs.

---

## ⚠ Before you touch anything

If your task is "run WordPress tests for plugin/theme X":

1. **Do NOT add plugin X's files, configs, or test scripts to this repo.** This template is OSS and must stay generic. Project-specific artifacts belong in the project's own overlay (see "Overlay layout" below).
2. **Do NOT modify** `docker-compose.yml`, `scripts/setup.sh`, `config/plugins.yaml`, or `.env.example` to make your project work. If you need to override behavior, do it via env vars in your overlay's `.env`.
3. **Do NOT commit a `.env`** with your project's secrets to this repo. `.env` is gitignored.
4. **Do clone this repo once** somewhere stable (e.g. `~/Documents/repositories/github/wp-test-env` or `~/wp-test-env`). Your project's overlay setup script will find it via env var `WP_TEST_ENV_ROOT` or auto-detection.

If your task is "extend wp-test-env's generic capabilities" (e.g. add a new database engine option, fix a docker-compose bug, add a new test helper that EVERY project would benefit from): yes, edit this repo directly.

---

## How this template is meant to be used

```
┌─────────────────────────────────────────────────────────────────────┐
│  Template (this repo) — OSS, generic, shared by all projects        │
│  /Users/andrelange/Documents/repositories/github/wp-test-env        │
│                                                                     │
│  • docker-compose.yml          (parametrized via env vars)          │
│  • scripts/setup.sh            (calls check-ports.sh, creates dirs) │
│  • scripts/check-ports.sh      (port-collision pre-flight)          │
│  • docs/overlay-pattern.md     (the convention)                     │
│  • .env.example                (defaults + comments)                │
│  • plugins/README.md           (placeholder — plugins/* gitignored) │
└─────────────────────────────────────────────────────────────────────┘
                                ▲
                                │ consumes (does NOT fork)
              ┌─────────────────┴─────────────────────────┐
              │                                           │
┌─────────────┴───────────────┐         ┌─────────────────┴─────────────────┐
│  Overlay (project-specific) │         │  Overlay (project-specific)        │
│  capacium-bridge-tests/     │         │  elementeer-ops/wp-testing-env/    │
│                             │         │                                    │
│  • .env.overlay (kennung)   │         │  • config/elementeer.env (kennung) │
│  • config/plugins.yaml      │         │  • config/plugins.yaml             │
│  • scripts/setup-overlay.sh │         │  • scripts/setup-elementeer.sh     │
│  • bundles/*.zip            │         │  • bundles/*.zip                   │
│  • tests/*.sh               │         │  • tests/*.sh                      │
│  • AGENTS.md / README.md    │         │  • AGENTS.md / README.md           │
└─────────────────────────────┘         └────────────────────────────────────┘
```

The overlay holds everything project-specific:
- Plugin under test (or symlink/cp into the isolated PLUGINS_DIR at setup time)
- Premium plugin ZIPs (in `bundles/`)
- The kennung (`COMPOSE_PROJECT_NAME`), port band, and per-instance bind-mount paths
- Project-specific smoke tests
- Project-specific plugin profile (`plugins.yaml`)

The template provides:
- Generic Docker stack (MySQL + WordPress + WP-CLI + phpMyAdmin + MailHog)
- Generic plugin installer (reads `config/plugins.yaml`, installs from wordpress.org / URL / local zips)
- Port-collision pre-flight (`check-ports.sh`)
- Per-instance state isolation (`COMPOSE_PROJECT_NAME` + `COMPOSE_PROJECT_DIR` + `PLUGINS_DIR`/`THEMES_DIR`/`UPLOADS_DIR`)

---

## Overlay layout (what your project repo should look like)

```
<your-project>-tests/                       ← your overlay repo
├── README.md
├── AGENTS.md                               ← project-specific agent rules
├── wp-testing-env/
│   ├── .env.overlay                        ← THE manifest: kennung + ports + paths
│   ├── config/
│   │   └── plugins.yaml                    ← your plugin profile
│   ├── bundles/                            ← premium ZIPs (gitignored)
│   ├── scripts/
│   │   └── setup-overlay.sh                ← your overlay's setup orchestrator
│   └── tests/                              ← project-specific smoke tests
```

Reference implementations:
- **Capacium:** https://github.com/Capacium/capacium-bridge-tests
- **Elementeer:** `/Users/andrelange/Documents/repositories/forgejo/elementeer/elementeer-ops/wp-testing-env`

---

## Minimum `.env.overlay` your overlay must declare

```bash
# Kennung — unique per overlay
COMPOSE_PROJECT_NAME=myproject-wptest
COMPOSE_PROJECT_DIR=envs/myproject-tests

# Port band — must not collide with other overlays
WORDPRESS_PORT=8084            # check pre-allocated bands in wp-test-env docs/overlay-pattern.md
MYSQL_PORT=3309
PHPMYADMIN_PORT=8085
MAILHOG_SMTP_PORT=1027
MAILHOG_WEB_PORT=8027

# Per-instance bind-mount paths (MUST be prefixed with ./ — see env.example)
PLUGINS_DIR=./envs/myproject-tests/plugins
THEMES_DIR=./envs/myproject-tests/themes
UPLOADS_DIR=./envs/myproject-tests/uploads

# Plugin profile from your overlay
PLUGINS_CONFIG=config/plugins.yaml

# DB creds — project-specific so they don't clash
MYSQL_DATABASE=myproject_test
MYSQL_USER=myproject
MYSQL_PASSWORD=myproject_test_password
WORDPRESS_TABLE_PREFIX=mp_
```

Pre-allocated port bands per overlay live in `docs/overlay-pattern.md`. Pick the next free band.

---

## Minimum `setup-overlay.sh` shape

```bash
#!/usr/bin/env bash
set -euo pipefail

# 1. Locate wp-test-env (env or auto-detect via sibling dirs)
WP_TEST_ENV_ROOT="${WP_TEST_ENV_ROOT:-$HOME/Documents/repositories/github/wp-test-env}"
[ -d "$WP_TEST_ENV_ROOT" ] || { echo "wp-test-env not found"; exit 1; }

# 2. Verify base supports multi-instance (v2.1+)
[ -x "$WP_TEST_ENV_ROOT/scripts/check-ports.sh" ] || {
  echo "wp-test-env base too old — needs v2.1+ (PR LangeVC/wp-test-env#7)"
  exit 1
}

# 3. Apply overlay manifest: stash existing, copy ours
[ -f "$WP_TEST_ENV_ROOT/.env" ] && \
  cp "$WP_TEST_ENV_ROOT/.env" "$WP_TEST_ENV_ROOT/.env.pre-myproject-$(date +%s)"
cp "$(dirname "$0")/../.env.overlay" "$WP_TEST_ENV_ROOT/.env"
cp "$(dirname "$0")/../config/plugins.yaml" "$WP_TEST_ENV_ROOT/config/plugins.yaml"

# 4. Run base setup (port-checks + docker compose up + plugin install)
(cd "$WP_TEST_ENV_ROOT" && ./scripts/setup.sh)

# 5. Drop your project's main plugin into the now-isolated PLUGINS_DIR
#    (NOT via docker cp into a shared container — write to the bind mount on host)
cp -r "$MY_PROJECT_SOURCE" "$WP_TEST_ENV_ROOT/envs/myproject-tests/plugins/my-plugin"

# 6. Activate via wp-cli + run smoke tests
docker exec myproject-wptest-wordpress wp plugin activate my-plugin --allow-root
bash "$(dirname "$0")/../tests/smoke-test.sh"
```

(See capacium-bridge-tests/wp-testing-env/scripts/setup-overlay.sh for the full reference.)

---

## Common pitfalls

| Pitfall | Why it bites | Fix |
|---------|--------------|-----|
| `docker exec wptesting-wordpress …` | "wptesting" is just the default — whatever overlay is on default ports owns it. Your dev machine probably has one already. | Use your own kennung's container name: `docker exec myproject-wptest-wordpress …` |
| `docker cp my-plugin INTO_CONTAINER:/var/www/html/wp-content/plugins/` | Writes to the BIND MOUNT, which (without `PLUGINS_DIR` override) is the SHARED `./plugins` dir → pollutes other overlays | Set `PLUGINS_DIR=./envs/<name>/plugins` and `cp` onto the host bind mount, not via `docker cp` into the shared default |
| `git add plugins/my-plugin/` in this template repo | OSS template must stay generic | Keep your plugin in YOUR repo. The overlay setup script drops it into the per-instance `PLUGINS_DIR` at runtime |
| Port 8082 hardcoded in tests | Breaks the moment two overlays run | Read `${WORDPRESS_PORT:-8082}` from env in your test scripts |
| Modifying `docker-compose.yml` per project | Causes merge conflicts; template loses genericity | Override via env vars in `.env.overlay` (the compose file already uses `${VAR:-default}` for everything that matters) |

---

## What you can change in this repo (and what you cannot)

| Change | OK? | Where to do it instead |
|--------|-----|------------------------|
| Fix a bug in `check-ports.sh` (e.g. handle IPv6 better) | ✅ yes | here |
| Add a new generic option (`REDIS_PORT`, `MEMCACHED_PORT`, …) | ✅ yes — but parametrize via env var | here |
| Add a new docker compose service that every overlay would want (e.g. wp-mailhog already there, maybe a reverse proxy) | ✅ yes — but parametrized + opt-in via env | here |
| Add a plugin you need for YOUR project | ❌ no | your overlay's `config/plugins.yaml` |
| Add a test script for YOUR plugin | ❌ no | your overlay's `tests/` |
| Commit a premium plugin ZIP | ❌ no — licensing + repo bloat | your overlay's `bundles/` (gitignored), or the user provides a download link |
| Hardcode a port for one project | ❌ no | overlay's `.env.overlay` |

When in doubt: this repo MUST install + run for any consumer using only the .env.example defaults. Nothing project-specific.

---

## Quick smoke test if you ARE modifying this template

```bash
cd ~/Documents/repositories/github/wp-test-env
git checkout main
git pull
cp .env.example .env
./scripts/setup.sh                # should fully bootstrap, no errors
curl -sf http://localhost:8082    # WP responds 200
./scripts/check-ports.sh          # all ports allocated to OUR stack now in use
docker compose down -v            # clean teardown
```

If any of those break, your change is not landable.

---

## References

- `docs/overlay-pattern.md` — full convention (port bands, naming, decision log)
- `README.md` — user-facing setup walkthrough
- `CHANGELOG.md` — what's new
- `.env.example` — defaults + per-field documentation
- `scripts/check-ports.sh` — port pre-flight (called by setup.sh)
