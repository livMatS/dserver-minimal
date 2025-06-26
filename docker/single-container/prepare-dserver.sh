#!/bin/sh

echo "-> Set postgres password"

su - postgres -c "psql -c \"ALTER USER postgres PASSWORD 'postgres';\""
su - postgres -c "psql -c \"CREATE DATABASE dtool;\""

echo "-> Creating keys..."
openssl genrsa -out /keys/jwt_key 2048
openssl rsa -in /keys/jwt_key -pubout -outform PEM -out /keys/jwt_key.pub

# Define the local data directory
DATA_DIR="/tmp/data"
mkdir -p ${DATA_DIR}

echo "-> Migrating database..."
flask db migrate
flask db upgrade

echo "-> Register base URI..."
flask base_uri add "file://$HOSTNAME$DATA_DIR"

echo "-> Creating test user..."
flask user add test-user

echo "-> Setting permissions for test user..."
flask user search_permission test-user "file://$HOSTNAME$DATA_DIR"

echo "-> Index base URI..."
flask base_uri index "file://$HOSTNAME$DATA_DIR"

# echo "-> Starting gunicorn..."
# exec gunicorn -b :5000 --access-logfile - --error-logfile - --log-level ${LOGLEVEL} wsgi:app
