#!/bin/bash

# Wait for Moodle to be fully up and running
echo "Waiting for Moodle to initialize..."
sleep 30

# Set Academi as the default theme using Moodle CLI
php /opt/bitnami/moodle/admin/cli/cfg.php --name=theme --set=academi

echo "Academi theme has been set as the default theme."
