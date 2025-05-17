#!/bin/bash

# This script will be automatically executed by MariaDB during its initialization process
# Bitnami MariaDB container runs scripts in /docker-entrypoint-initdb.d/ in alphabetical order
# We name this with "99-" prefix to ensure it runs after the database is fully set up

echo "====== Importing sample data for Moodle ======"
mysql -u "$MARIADB_USER" -p"$MARIADB_PASSWORD" "$MARIADB_DATABASE" < /docker-entrypoint-initdb.d/sample_data.sql
echo "====== Sample data import completed ======"
