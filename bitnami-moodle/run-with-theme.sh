#!/bin/bash

echo "Starting Moodle with the Academi theme..."

# Start the containers
docker compose up -d

# Wait for Moodle to be ready
echo "Waiting for Moodle to be fully up and running..."
sleep 60

# Execute the theme application script inside the container
docker compose exec -T moodle /bin/bash /opt/bitnami/scripts/apply-theme.sh

echo "Moodle is now running with the Academi theme!"
echo "You can access it at http://localhost:80"
