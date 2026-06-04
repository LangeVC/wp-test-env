# Overlay Pattern — running multiple wp-test-env instances in parallel

wp-test-env is a generic WordPress testing harness. Plugin/theme projects (overlays)
sit on top of it: capacium-bridge-tests, elementeer-tests, etc. Two or more
overlays must be able to run in parallel on the same machine without colliding.

This doc codifies how an overlay declares its identity and how it stays out of
other overlays' way.

## TL;DR

An overlay ships a single `.env.overlay` file (or any `.env` it tells the user
to copy) that sets at minimum:

```bash
# Kennung (outside-visible identifier)
COMPOSE_PROJECT_NAME=capacium-wptest          # MUST be unique per overlay
COMPOSE_PROJECT_DIR=envs/capacium-bridge-tests # MUST be unique per overlay

# Ports — MUST be free; check-ports.sh fails fast otherwise
WORDPRESS_PORT=8083
MYSQL_PORT=3307
PHPMYADMIN_PORT=8084
MAILHOG_SMTP_PORT=1026
MAILHOG_WEB_PORT=8026
```

Then the overlay's setup script does:

```bash
cd /path/to/wp-test-env
cp /path/to/overlay/.env.overlay .env
./scripts/check-ports.sh      # fail fast if any port is taken
./scripts/setup.sh            # start the stack
```

That's it. Each overlay's containers carry the `${COMPOSE_PROJECT_NAME}-` prefix
and live in isolated docker networks/volumes. Two overlays with different
COMPOSE_PROJECT_NAME + non-colliding ports coexist cleanly.

## Naming convention

- `COMPOSE_PROJECT_NAME` — kebab-case, suffixed `-wptest` to make it obvious
  this is a wp-test-env-derived stack:
  - `elementeer-wptest`  (or just `wptesting` = default)
  - `capacium-wptest`
  - `myplugin-wptest`
- `COMPOSE_PROJECT_DIR` — `envs/<overlay-repo-slug>` keeps per-overlay state
  (uploads, logs, reports) under wp-test-env's `envs/` folder. State stays
  isolated even if the same `wp-test-env/` checkout is reused.

## Port allocation strategy

Each overlay picks a port band offset by +1 from the previous overlay's:

| Slot | Default (`wptesting`) | Suggested second (`capacium-wptest`) | Suggested third |
|------|----------------------|--------------------------------------|------------------|
| WORDPRESS_PORT | 8082 | 8083 | 8084 |
| MYSQL_PORT     | 3306 | 3307 | 3308 |
| PHPMYADMIN_PORT| 8092 | 8093 | 8094 |
| MAILHOG_SMTP_PORT | 1025 | 1026 | 1027 |
| MAILHOG_WEB_PORT  | 8025 | 8026 | 8027 |

Pick the next free slot when you set up a new overlay. The collision check
catches accidents.

Note: `PHPMYADMIN_PORT` default in `.env.example` is 8083 (one above WP).
For consistency we recommend bands of +10 between adjacent overlays so each
overlay's 5 ports stay grouped — but for a 2-overlay setup, +1 is fine.

## How an overlay should be structured

```
<your-overlay>-tests/
├── README.md                     ← how to use this overlay
├── AGENTS.md                     ← agent-readable usage notes
├── wp-testing-env/
│   ├── .env.overlay              ← THE overlay manifest (the "kennung")
│   ├── config/
│   │   └── plugins.yaml          ← plugin profile for this overlay
│   ├── bundles/                  ← premium plugin ZIPs (gitignored)
│   ├── scripts/
│   │   └── setup-overlay.sh      ← deploy plugin from local source + activate
│   └── tests/
│       ├── smoke-test.sh         ← uses ${WORDPRESS_PORT:-8082} from env
│       ├── ...
```

The `.env.overlay` file is the kennung. The setup script copies it to
`wp-test-env/.env`, then runs `check-ports.sh` + `setup.sh`. Tests read
their target URL from `WORDPRESS_PORT` so they hit the right overlay.

## Coexisting with another overlay

To run capacium-bridge-tests alongside elementeer-tests on the same machine:

1. **Pick non-colliding ports** for each overlay (see table above).
2. **Pick distinct COMPOSE_PROJECT_NAME** for each (e.g. `elementeer-wptest`
   and `capacium-wptest`).
3. **Pick distinct COMPOSE_PROJECT_DIR** for each (e.g.
   `envs/elementeer-tests` and `envs/capacium-bridge-tests`).
4. **Run `check-ports.sh` before each setup**. If the elementeer stack is
   already running, the capacium-wptest setup's check will detect any port
   collision and fail with a clear message.

After both are up, `docker ps` shows them as separate stacks:

```
$ docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}'
NAMES                              IMAGE              PORTS
elementeer-wptest-wordpress        wordpress:latest   0.0.0.0:8082->80/tcp
elementeer-wptest-mysql            mysql:8.0          0.0.0.0:3306->3306/tcp
capacium-wptest-wordpress          wordpress:latest   0.0.0.0:8083->80/tcp
capacium-wptest-mysql              mysql:8.0          0.0.0.0:3307->3306/tcp
```

Tear down one without affecting the other:

```bash
docker compose --env-file .env -p capacium-wptest down -v   # only capacium
docker compose --env-file .env -p elementeer-wptest down -v # only elementeer
```

## Port collision check

`scripts/check-ports.sh` (in wp-test-env) probes the host BEFORE docker compose
up. It:

- Reads ports from `.env` (or accepts explicit args).
- For each port: checks Docker containers first (`docker ps -f publish=<port>`),
  then host processes (`lsof -i:<port>`).
- Exits 0 if all free; exits 1 with a clear error message listing each
  occupied port + what's holding it.

Integrate it into your overlay's setup script:

```bash
# Pre-flight before docker compose up
"${WP_TEST_ENV_ROOT}/scripts/check-ports.sh" || {
    err "Cannot start ${MY_OVERLAY} — port collision (see above)"
    exit 1
}
```

## Decision log: why this design

- **`COMPOSE_PROJECT_NAME` over docker-compose `name:` field**: env-var is
  inherited by ALL `docker compose` invocations in the same shell, including
  ad-hoc `docker compose down -v` commands. The compose-file `name:` is also
  fine but requires modifying the file per overlay.
- **State subdir under `envs/`** over fork-per-overlay: a single wp-test-env
  checkout can host multiple overlays without git divergence.
- **Port check as pre-flight script** over silent docker bind-mount failures:
  Docker errors on port conflict are noisy and don't tell you what's holding
  the port. Explicit script gives actionable output.

## See also

- `scripts/check-ports.sh` — the port-collision pre-flight
- `scripts/setup.sh` — main bootstrap; reads .env, starts stack
- `.env.example` — default values for the primary instance
- `docs/multi-instance-coexistence.md` (planned) — operations runbook for
  managing multiple overlays in CI / on dev machines
