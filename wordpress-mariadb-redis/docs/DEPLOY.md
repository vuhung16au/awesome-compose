# Deployment Instructions

## Prerequisites

- Docker and Docker Compose installed
- At least 2GB of RAM available for the containers
- Ports 80, 443, 6379, 6380, and 8080 available on your host

## Standard Deployment

To deploy the complete stack:

```bash
docker compose up -d
```

Example output for standard deployment:

```console
[+] Running 8/8
 ✔ Network wordpress-mariadb-redis_wp_network        Created   0.0s
 ✔ Container wordpress-mariadb-redis-mariadb-1       Started   0.6s
 ✔ Container wordpress-mariadb-redis-redis-1-1       Started   0.2s
 ✔ Container wordpress-mariadb-redis-redis-2-1       Started   0.2s
 ✔ Container wordpress-mariadb-redis-wordpress-1-1   Started   0.3s
 ✔ Container wordpress-mariadb-redis-wordpress-2-1   Started   0.3s
 ✔ Container wordpress-mariadb-redis-wordpress-3-1   Started   0.3s
 ✔ Container wordpress-mariadb-redis-phpmyadmin-1    Started   0.3s
 ✔ Container wordpress-mariadb-redis-nginx-1         Started   0.2s
```

### Note on Multiple Instances

The default configuration already includes 3 WordPress instances and 2 Redis instances, so no additional scaling commands are needed. This provides built-in load balancing and redundancy.

## Verifying Deployment

Check containers are running and the port mapping:

```bash
docker ps
```

After deployment, verify the monitoring stack:

- Access **Prometheus UI** at [http://localhost:9090](http://localhost:9090)
- Access **Grafana UI** at [http://localhost:3000](http://localhost:3000) (default user: `admin`, password: `admin`)

You should see all services and exporters listed as targets in Prometheus, and be able to import dashboards in Grafana.

Example output:

```console
CONTAINER ID   IMAGE                              COMMAND                  CREATED          STATUS          PORTS                  NAMES
a4feb59bab20   nginx:stable-alpine                "nginx -g 'daemon of…"   46 seconds ago   Up 46 seconds   0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp   wordpress-mariadb-redis-nginx-1
d4feb59bab20   wordpress-mariadb-redis-wordpress-1 ...                    Up 46 seconds    80/tcp                wordpress-mariadb-redis-wordpress-1-1
c5feb59bab21   wordpress-mariadb-redis-wordpress-2 ...                    Up 46 seconds    80/tcp                wordpress-mariadb-redis-wordpress-2-1
b6feb59bab22   wordpress-mariadb-redis-wordpress-3 ...                    Up 46 seconds    80/tcp                wordpress-mariadb-redis-wordpress-3-1
0ff2639f74ca   mariadb:10                         ...                     Up 46 seconds    3306/tcp              wordpress-mariadb-redis-mariadb-1
e7c1c45e1f9a   redis:7.2-alpine                  ...                     Up 46 seconds    0.0.0.0:6379->6379/tcp wordpress-mariadb-redis-redis-1-1
f8d1e45e1f9b   redis:7.2-alpine                  ...                     Up 46 seconds    0.0.0.0:6380->6379/tcp wordpress-mariadb-redis-redis-2-1
8ad2f721be3c   wordpress-mariadb-redis-phpmyadmin ...                     Up 46 seconds    0.0.0.0:8080->80/tcp  wordpress-mariadb-redis-phpmyadmin-1
```

## Accessing Services

### WordPress

Navigate to `https://localhost/` in your web browser to access WordPress securely. The HTTPS connection ensures that all data transmitted between your browser and the WordPress site is encrypted.

![Wordpress Installation](../wordpress-installation.png)

After installation, go to your WordPress admin panel and activate the Redis Object Cache plugin to enable Redis caching.

#### Redis Object Cache Configuration

1. Log in to your WordPress admin panel (typically at `https://localhost/wp-admin/`)
2. Go to Plugins > Installed Plugins
3. Locate and activate the "Redis Object Cache" plugin
4. Go to Settings > Redis (it should appear after activation)
5. Click the "Enable Object Cache" button to start using Redis

Once enabled, WordPress will store database query results, objects, and transient data in Redis, significantly improving page load times and reducing database load.

### phpMyAdmin

Navigate to `http://localhost:8080` to access phpMyAdmin:

- **Server**: mariadb
- **Username**: wordpress
- **Password**: wordpress

phpMyAdmin provides a web interface for:

- Managing database tables and records
- Importing and exporting data
- Running SQL queries
- Monitoring database performance

## HTTPS Support

The configuration includes full support for HTTPS to secure your WordPress site:

1. Self-signed certificates are automatically generated using the included `../generate-ssl-certs.sh` script
2. SSL certificates are stored in the `./nginx/ssl/` directory
3. HTTPS is enabled by default with the proper configuration in `./nginx/default.conf`
4. Automatic HTTP to HTTPS redirection is configured for enforced secure connections
5. Modern SSL protocols (TLSv1.2 and TLSv1.3) are enabled with secure cipher configurations

To access the site securely, simply navigate to `https://localhost/` in your web browser. Note that since the certificates are self-signed, you may need to accept a security warning in your browser during local development.

## Connectivity Testing

To verify that all services are properly connected and functioning, you can use the included connectivity test script:

```bash
# Make the script executable first (if needed)
chmod +x ../test-wordpress.sh

# Run the test script
../test-wordpress.sh
```

The script performs the following checks:
- Verifies that all containers are running
- Tests NGINX and its load balancing configuration
- Tests if WordPress is accessible through NGINX
- Tests if phpMyAdmin is accessible
- Verifies the WordPress to MariaDB connection
- Confirms Redis connectivity and password authentication
- Checks if the Redis PHP module is installed in WordPress
- Verifies Redis Object Cache plugin installation
- Examines NGINX, Apache, and PHP logs for errors
- Displays WordPress configuration settings

This script is useful for troubleshooting connection issues and ensuring all components of the stack are working together properly.

## Stopping Services

```bash
docker compose down
```

To remove all WordPress data, delete the named volumes by passing the `-v` parameter:

```bash
docker compose down -v
```
