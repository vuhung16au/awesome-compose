#!/bin/bash
echo "This initialization script will import sample data into the Moodle database"
mysql -u bn_moodle -pbitnami bitnami_moodle < /docker-entrypoint-initdb.d/sample_data.sql
