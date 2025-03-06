#!/bin/sh
if [ ! -d migrations ]; then
    echo "-> Initialize database..."
    flask db init
fi

echo "-> Migrating database..."
flask db migrate
flask db upgrade

DATA_DIR="/tmp/data"

echo "-> Register base URI..."
flask base_uri add "file://$DATA_DIR"

echo "-> Creating test user..."
flask user add test-user

echo "-> Setting permissions for test user..."
flask user search_permission test-user "file://$DATA_DIR"

echo "-> Index base URI..."
flask base_uri index "file://$DATA_DIR"
