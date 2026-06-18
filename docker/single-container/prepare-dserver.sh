#!/bin/bash
# One-shot bootstrap for the single-container dserver. Idempotent: safe to run
# again on a restarted container. Run by supervisord after the databases start.
set -o errexit
set -o pipefail
set -o nounset

DATA_DIR="/tmp/data"
BASE_URI="file://${HOSTNAME}${DATA_DIR}"

echo "-> Waiting for PostgreSQL..."
until pg_isready -h localhost -U postgres >/dev/null 2>&1; do
    sleep 1
done

echo "-> Waiting for MongoDB..."
until mongosh --quiet --eval 'db.runCommand({ ping: 1 }).ok' >/dev/null 2>&1; do
    sleep 1
done

echo "-> Configuring PostgreSQL role and database..."
su - postgres -c "psql -c \"ALTER USER postgres PASSWORD 'postgres';\""
# Create the application database only if it does not exist yet.
su - postgres -c "psql -tAc \"SELECT 1 FROM pg_database WHERE datname='dtool'\"" \
    | grep -q 1 || su - postgres -c "psql -c \"CREATE DATABASE dtool;\""

echo "-> Generating JWT keys (used only if auth is enabled)..."
mkdir -p /keys
if [ ! -f /keys/jwt_key ]; then
    openssl genrsa -out /keys/jwt_key 2048
    openssl rsa -in /keys/jwt_key -pubout -outform PEM -out /keys/jwt_key.pub
fi

mkdir -p "${DATA_DIR}"

# Generate the migration scripts once (first boot), then only ever apply them.
# Running `flask db migrate` on every boot risks autogenerating spurious
# migrations against a populated database.
if [ ! -d migrations ]; then
    echo "-> Initializing migrations and generating initial schema..."
    flask db init
    flask db migrate -m "initial schema"
fi
echo "-> Applying database migrations..."
flask db upgrade

echo "-> Registering base URI ${BASE_URI}..."
flask base_uri add "${BASE_URI}" 2>/dev/null || echo "   base URI already registered"

echo "-> Ensuring test user..."
flask user add test-user 2>/dev/null || echo "   user already exists"

echo "-> Granting permissions..."
flask user search_permission test-user "${BASE_URI}" 2>/dev/null || true
flask user register_permission test-user "${BASE_URI}" 2>/dev/null || true

echo "-> Indexing datasets under ${BASE_URI}..."
flask base_uri index "${BASE_URI}"

echo "-> Bootstrap complete."
