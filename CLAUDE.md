# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

`dserver-minimal` is a **meta-package**, not an application. Its only Python
payload is `dserver_minimal/__init__.py` (version detection boilerplate). The
real value is twofold:

1. **`pyproject.toml` dependency pins** — installing `dserver-minimal` pulls in
   a known-good set of `dservercore` + the Mongo search/retrieve plugins. When
   asked to "bump" or "update" dserver, the change is almost always editing the
   version constraints in `pyproject.toml` and recording it in `CHANGELOG.rst`.
2. **Development and deployment harnesses** (`devel/`, `docker/`) that stand up
   a working dserver instance against real backing services.

There is **no test suite** and **no application logic** to modify here. The
actual server code lives in the upstream repos: `dservercore`
(github.com/jic-dtool/dservercore), `dserver-search-plugin-mongo`,
`dserver-retrieve-plugin-mongo`, and optional plugins (`dserver-direct-mongo-plugin`,
`dserver-dependency-graph-plugin`, `dserver-notification-plugin`). To change
server behavior, clone and `pip install -e` those repos (see `devel/README.md`).

## Architecture: how a dserver instance is assembled

dserver is a Flask app created by `dservercore.create_app()`. It is entirely
**configured through environment variables** — there is no config file for the
app itself. The three concerns are split across separate backing stores:

- **PostgreSQL** (`SQLALCHEMY_DATABASE_URI`) — users, permissions, base URIs,
  dataset registry. Schema is managed by Flask-Migrate (`flask db ...`).
- **MongoDB** — search index (`SEARCH_MONGO_*`), retrieve store
  (`RETRIEVE_MONGO_*`), and, with the direct-mongo plugin, raw metadata queries
  (`DSERVER_MONGO_*` / `DSERVER_ALLOW_DIRECT_AGGREGATION`).
- **Object/file storage** — datasets live under a registered *base URI*
  (`file://...` or `s3://...`); dserver indexes them but does not store them.

`wsgi.py` is the entrypoint that wraps `create_app()`. It adds two env-driven
debug behaviors: `LOGLEVEL` (sets root logger) and `DUMP_HTTP_REQUESTS=True`
(WSGI middleware that pprints every request/response). The single-container
deployment ships its own copy at `docker/single-container/wsgi.py`.

Authentication is JWT-based, with tokens minted by a **separate** token
generator service (not part of dserver). For local work, auth is typically
disabled via `DISABLE_JWT_AUTHORISATION=True` + `DEFAULT_USER=test-user`.

The route `/config/versions` lists all installed server-side plugins and their
versions without auth — use it to confirm which plugins a running instance loaded.

## Common commands

### Uncontainerized local development (`devel/`)
Bring up backing services (Postgres, Mongo, Minio S3, LDAP, token generator):
```bash
mkdir -p docker/keys                       # bind mount for JWT keys; compose fails without it
docker compose -f docker/env.yml up -d
sudo chown -R ${USER}:${USER} docker/keys  # make generated keys host-readable
```
Then, in a venv with dserver + plugins installed:
```bash
cp devel/dtool.json ~/.config/dtool/dtool.json
source devel/env.rc        # exports all FLASK_APP / *_MONGO_URI / SQLALCHEMY_* vars
bash devel/init.sh         # flask db init/migrate/upgrade, add base_uri + test-user, index
bash devel/run.sh          # gunicorn on :5000  (Swagger at http://localhost:5000/doc/swagger)
bash devel/create_test_data.sh   # builds two dtool datasets and pushes them to s3://test-bucket
```
`FLASK_APP=dservercore`, so `flask <cmd>` admin commands (`flask base_uri add`,
`flask user add`, `flask user search_permission`, `flask base_uri index`,
`flask db ...`) operate on the configured stores once `env.rc` is sourced.

### Containerized dserver (`docker/`)
- `docker compose -f docker/devel.yml up --build` — full stack incl. dserver
  (built from `docker/dserver_devel/Dockerfile`) and the lookup webapp (:8080).
  dserver on `https://localhost:5000`, auth disabled.
- `docker compose -f docker/env.yml up -d` — backing services **only** (for the
  uncontainerized flow above, or to try alternate plugin sets).
- Single all-in-one container (nginx + Postgres + Mongo + webapp + dserver via
  `supervisord`):
  ```bash
  docker build -t livmats/dserver-minimal docker/single-container
  docker run -v $(pwd)/sample-datasets:/tmp/data:ro -p 8888:8888 livmats/dserver-minimal
  ```
  It indexes datasets found in the mounted `/tmp/data`; nginx serves the API
  under the `/lookup` prefix (`SCRIPT_NAME=/lookup`).

### Mint a token (when auth is enabled)
```bash
curl --insecure -H "Content-Type: application/json" \
  -X POST -d '{"username": "test-user", "password": "test-password"}' \
  http://localhost:5001/token
```

### Docs
```bash
pip install -e ".[docs]"
make -C docs html
```
`docs/development.rst` simply includes `devel/README.md` and `docker/README.md`
via myst-parser — keep development instructions in those READMEs, not duplicated
in the `.rst`.

## Single-container image (`docker/single-container/`)

The "try dserver with one `docker run`" artifact — a whole stack (PostgreSQL +
MongoDB + dserver API + Vue web GUI) inside **one** image fronted by nginx on
port **8888**. Distinct from the multi-service `docker compose` setups; published
to `ghcr.io/livmats/dserver-minimal` by `publish-container-image.yml`.

**Build (`Dockerfile`)** is **multi-stage**:
- Stage `webapp-builder` (`node:20-bookworm-slim`) builds the web GUI. The GUI
  tracks `jic-dtool/dtool-lookup-webapp` (branch via `WEBAPP_REF`), which has a
  `file:` dependency on `livMatS/dserver-client-js` (branch via `CLIENT_JS_REF`)
  — so the client lib is built first, the `file:` path is rewritten, and
  `npm run build` produces a static `dist/`. Build-time config (`webapp.env`,
  incl. `VUE_APP_AUTH_ENABLED=false`) is baked into the bundle.
- Runtime stage (`python:3.12-slim-bookworm`) apt-installs nginx + PostgreSQL +
  MongoDB 8.0 + supervisor + git, then `pip install`s `requirements.txt`: the
  dserver **core and plugins plus the dtool stack from their GitHub default
  branches** (`jic-dtool/*` on `master`, `livMatS/*` on `main`; latest dev
  state, intentionally unpinned) and a Flask-stack
  compatibility cap (`Flask==2.3.3`/`Werkzeug==2.3.8`/`marshmallow<4` — without
  it the resolver pulls marshmallow 4 / Werkzeug 3 and drags `flask-smorest`
  down to an ancient `MethodViewType`-importing release). `psycopg2-binary` so
  no compiler. The static GUI is copied to `/var/www/dtool-lookup-webapp`; no
  Node/Yarn in the final image.

**Runtime** is `supervisord` running four long-lived programs (priority-ordered:
postgresql → mongodb → dserver gunicorn `:5000` → nginx) plus a one-shot
`prepare-dserver.sh`. The bootstrap waits for both DBs (`pg_isready` / `mongosh
ping`), generates migrations only on first boot then `flask db upgrade`,
registers base URI `file://$HOSTNAME/tmp/data`, seeds `test-user`, and indexes —
all idempotent. Mount datasets read-only at `/tmp/data`.

**Routing**: nginx 8888 proxies `/lookup` → dserver `:5000` (prefix **not**
stripped; dserver runs with `SCRIPT_NAME=/lookup`) and serves the static GUI at
`/` directly (`root /var/www/...; try_files ... /index.html`). Auth is disabled
(`DISABLE_JWT_AUTHORISATION=True` + `DEFAULT_USER=test-user`), matched by the
webapp's `VUE_APP_AUTH_ENABLED=false`. A `HEALTHCHECK` hits
`/lookup/config/health`.

Still **demo/eval only**: embedded DBs, disabled auth, throwaway credentials
(`test-user`/`postgres`). To pin the GUI for reproducibility, pass a commit SHA
via `--build-arg WEBAPP_REF=<sha>` / `CLIENT_JS_REF=<sha>`.

## Conventions

- **Versioning** is `setuptools_scm`-driven from git tags (`local_scheme =
  "no-local-version"`); the version is written to `dserver_minimal/version.py`
  (gitignored) at build time. Don't hand-edit versions.
- **Releasing** = tag the commit; `.github/workflows/publish-python-package.yml`
  publishes to PyPI, `publish-container-image.yml` pushes container images. CI
  (`containers.yml`) only builds `docker/dserver_devel/Dockerfile` on push/PR —
  there are no unit tests in CI.
- **PyPI publishing uses Trusted Publishing (OIDC)** — no API tokens. It needs a
  one-time trusted-publisher setup on each index (project → Publishing): owner
  `livMatS`, repo `dserver-minimal`, workflow `publish-python-package.yml`, and
  the GitHub **environment name** the publish job declares — `pypi` on PyPI,
  `testpypi` on TestPyPI. The `publish-pypi` / `publish-testpypi` jobs set those
  `environment:` names; without the matching trusted publisher, releases fail.
- Every change goes under the `[unpublished]` section of `CHANGELOG.rst`
  (Keep a Changelog format, semantic versioning).
- The `devel/` and `docker/devel.yml` / `single-container` setups use
  **throwaway credentials** (`admin:secret12`, `test-user:test-password`) and
  disabled auth — they are for local development only.
