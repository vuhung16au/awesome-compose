#!/bin/bash
# Wait for MariaDB to be ready
echo "Waiting for MariaDB to start..."
while ! mysql -h mariadb -u bn_moodle -pbitnami bitnami_moodle -e "SELECT 1" >/dev/null 2>&1; do
    sleep 5
    echo "Still waiting for MariaDB..."
done

echo "MariaDB is up and running"

# Import the sample data
echo "Importing sample data..."
mysql -h mariadb -u bn_moodle -pbitnami bitnami_moodle < /docker-entrypoint-initdb.d/sample_data.sql
echo "Sample data imported successfully"
