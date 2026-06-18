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

## Conventions

- **Versioning** is `setuptools_scm`-driven from git tags (`local_scheme =
  "no-local-version"`); the version is written to `dserver_minimal/version.py`
  (gitignored) at build time. Don't hand-edit versions.
- **Releasing** = tag the commit; `.github/workflows/publish-python-package.yml`
  publishes to PyPI, `publish-container-image.yml` pushes container images. CI
  (`containers.yml`) only builds `docker/dserver_devel/Dockerfile` on push/PR —
  there are no unit tests in CI.
- Every change goes under the `[unpublished]` section of `CHANGELOG.rst`
  (Keep a Changelog format, semantic versioning).
- The `devel/` and `docker/devel.yml` / `single-container` setups use
  **throwaway credentials** (`admin:secret12`, `test-user:test-password`) and
  disabled auth — they are for local development only.
