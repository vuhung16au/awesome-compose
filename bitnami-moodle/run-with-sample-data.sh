#!/bin/bash

# Navigate to script directory
cd "$(dirname "$0")"

echo "===== Starting Moodle with sample data ====="
echo "1. Stopping any existing containers and removing volumes..."
docker-compose down -v

echo "2. Starting Docker containers..."
docker-compose up -d

echo "3. Sample data will be imported automatically by the initialization scripts."
echo "   This process may take a minute or two to complete."
echo

echo "===== Access Information ====="
echo "Moodle: http://localhost:80"
echo "PHPMyAdmin: http://localhost:8080"
echo
echo "Default login information:"
echo "- Student account: student1 / password"
echo "- Teacher account: teacher1 / password"
echo "- Admin account: admin1 / password"
echo
echo "Note: If this is the first time starting Moodle, it may take a few minutes to set up."
