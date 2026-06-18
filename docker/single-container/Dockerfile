# =============================================================================
# dserver single-container image
#
# A whole dserver stack (PostgreSQL + MongoDB + dserver REST API + Vue web GUI)
# in one image, fronted by nginx on port 8888. Demo/evaluation artifact only:
# embedded databases, disabled auth, throwaway credentials.
#
#   docker build -t livmats/dserver-minimal docker/single-container
#   docker run -v $(pwd)/sample-datasets:/tmp/data:ro -p 8888:8888 livmats/dserver-minimal
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: build the static web GUI (discarded from the final image).
#
# The webapp has a local `file:` dependency on dserver-client-js, so that
# companion library is built first and linked in. Tracks the upstream branches
# by default; override CLIENT_JS_REF / WEBAPP_REF with a commit SHA to pin.
# -----------------------------------------------------------------------------
FROM node:26-bookworm-slim AS webapp-builder

ARG CLIENT_JS_REF=main
ARG WEBAPP_REF=master

# git to fetch sources; build-essential/python3 for any native node addons.
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        git ca-certificates build-essential python3 \
    && rm -rf /var/lib/apt/lists/*

# Build the JS client library the webapp depends on.
RUN git clone --depth 1 --branch ${CLIENT_JS_REF} \
        https://github.com/livMatS/dserver-client-js.git /dserver-client-js
WORKDIR /dserver-client-js
RUN npm install && npm run build

# Fetch the webapp (the Vue app lives in a subdirectory of the repo).
RUN git clone --depth 1 --branch ${WEBAPP_REF} \
        https://github.com/jic-dtool/dtool-lookup-webapp.git /tmp/webapp-src
WORKDIR /webapp
# Rewrite the local dependency path and drop the committed lockfile: it pins
# dserver-client to the original relative path, and npm crashes on the mismatch
# ("Cannot read properties of undefined (reading 'extraneous')"). npm install
# regenerates a fresh lockfile against the rewritten path.
RUN cp -a /tmp/webapp-src/dtool-lookup-webapp/. /webapp/ \
    && sed -i 's|file:../../dserver-client-js|file:/dserver-client-js|g' package.json \
    && rm -f package-lock.json

# Bake build-time configuration, install, and produce the static bundle in dist/.
COPY webapp.env /webapp/.env
RUN npm install && npm run build

# -----------------------------------------------------------------------------
# Stage 2: runtime image.
#
# python:3.12-slim (Debian bookworm) gives a modern Python without the
# externally-managed-environment hack; Postgres/Mongo/nginx come from apt.
# -----------------------------------------------------------------------------
FROM python:3.12-slim-bookworm

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PG_VERSION=15 \
    FLASK_APP=dservercore

# System services: nginx, PostgreSQL, MongoDB 8.0, supervisor.
RUN apt-get update \
    && apt-get install --yes --no-install-recommends gnupg curl ca-certificates \
    && curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc \
        | gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor \
    && echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main" \
        > /etc/apt/sources.list.d/mongodb-org-8.0.list \
    && apt-get update \
    && apt-get install --yes --no-install-recommends \
        nginx \
        postgresql postgresql-client \
        mongodb-org \
        supervisor \
        openssl \
        git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Python stack: dserver core + plugins and the dtool stack from their GitHub
# default branches (binary psycopg2 wheel → no compiler; git → clone from GitHub).
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt \
    && rm -f /tmp/requirements.txt

# Static web GUI from the builder stage, served directly by nginx.
COPY --from=webapp-builder /webapp/dist /var/www/dtool-lookup-webapp

# MongoDB data directory.
RUN mkdir -p /data/db && chown -R mongodb:mongodb /data/db

# Configuration and helper scripts.
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY prepare-dserver.sh /prepare-dserver.sh
COPY wsgi.py /dserver/wsgi.py
RUN mkdir -p /root/.config/dtool
COPY dtool.json /root/.config/dtool/dtool.json
RUN chmod +x /prepare-dserver.sh \
    && rm -f /etc/nginx/sites-enabled/default

# dserver configuration (all via environment; override at `docker run` as needed).
ENV SQLALCHEMY_DATABASE_URI=postgresql://postgres:postgres@localhost:5432/dtool \
    SEARCH_MONGO_URI=mongodb://localhost:27017/ \
    SEARCH_MONGO_DB=dtool_info \
    SEARCH_MONGO_COLLECTION=datasets \
    RETRIEVE_MONGO_URI=mongodb://localhost:27017/ \
    RETRIEVE_MONGO_DB=dtool_info \
    RETRIEVE_MONGO_COLLECTION=datasets \
    MONGO_URI=mongodb://localhost:27017/ \
    MONGO_DB=dtool_info \
    MONGO_COLLECTION=metadata \
    DSERVER_ALLOW_DIRECT_QUERY=True \
    DSERVER_ALLOW_DIRECT_AGGREGATION=True \
    DSERVER_ENABLE_DEPENDENCY_VIEW=True \
    DSERVER_DYNAMIC_DEPENDENCY_KEYS=True \
    DISABLE_JWT_AUTHORISATION=True \
    DEFAULT_USER=test-user \
    DUMP_HTTP_REQUESTS=False \
    LOGLEVEL=DEBUG \
    SCRIPT_NAME=/lookup \
    API_SPEC_OPTIONS='{ "x-internal-id": "2", "servers": [ { "url": "http://localhost:8888/lookup", "description": "dserver" } ] }'

# nginx is the only port that needs publishing.
EXPOSE 8888

HEALTHCHECK --interval=30s --timeout=5s --start-period=90s --retries=5 \
    CMD curl -sf http://localhost:8888/lookup/config/health || exit 1

CMD ["/usr/bin/supervisord", "-n"]
