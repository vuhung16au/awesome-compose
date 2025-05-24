#!/bin/sh
# This script installs the Redis Object Cache plugin for WordPress

# Create plugins directory if it doesn't exist
mkdir -p /var/www/html/wp-content/plugins

# Download Redis Object Cache plugin from WordPress.org
curl -o /tmp/redis-cache.zip -L https://downloads.wordpress.org/plugin/redis-cache.latest-stable.zip

# Install unzip if it's not available
if ! command -v unzip &> /dev/null; then
    apk add --no-cache unzip
fi

# Extract the plugin to the plugins directory
unzip -o /tmp/redis-cache.zip -d /var/www/html/wp-content/plugins/
rm /tmp/redis-cache.zip

# Set proper permissions
chown -R apache:apache /var/www/html/wp-content/plugins/

echo "Redis Object Cache plugin has been installed."
