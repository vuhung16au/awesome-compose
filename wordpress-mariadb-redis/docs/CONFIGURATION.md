# Configuration Details

This document provides detailed configuration information for each service in the WordPress, MariaDB, and Redis setup.

## NGINX Configuration

The NGINX setup consists of two main configuration files:

1. **nginx.conf**: Contains global NGINX settings
2. **default.conf**: Contains the site-specific configuration including load balancing

These files are located in the `./nginx/` directory and are mounted as read-only volumes in the NGINX container.

### Key NGINX Optimizations

- Used stable-alpine image for reduced size
- Optimized for WordPress with specialized settings
- Configured for load balancing multiple WordPress instances
- Implemented HTTPS with SSL/TLS termination for secure connections
- Set up caching for static assets to improve performance
- Implemented gzip compression to reduce bandwidth usage
- Configured automatic HTTP to HTTPS redirection for security

## WordPress Configuration

The WordPress containers are built using a custom Dockerfile (`Dockerfile.wordpress`) with several optimizations:

- Configured three separate WordPress instances for load balancing and redundancy
- Each WordPress instance has its own configuration but shares the same database
- WordPress instances 1 and 3 connect to Redis-1, while WordPress instance 2 connects to Redis-2
- Fixed entrypoint script with proper newline handling using `echo -e`
- Optimized Apache and PHP-FPM configuration for better performance
- Used Alpine as base image with PHP 8.2 to reduce overall size
- Installed PHP Redis extension for object caching
- Included Redis Object Cache plugin for WordPress
- All instances share a common uploads directory via volume mount for consistent media library

### WordPress Environment Variables

| Variable | Description | Default Value |
|----------|-------------|---------------|
| WORDPRESS_DB_HOST | Database hostname | mariadb |
| WORDPRESS_DB_USER | Database username | wordpress |
| WORDPRESS_DB_PASSWORD | Database password | wordpress |
| WORDPRESS_DB_NAME | Database name | wordpress |
| WORDPRESS_REDIS_HOST | Redis hostname | redis-1 or redis-2 |
| WORDPRESS_REDIS_PASSWORD | Redis password | wordpress_redis |

## phpMyAdmin Configuration

phpMyAdmin is built using a custom Dockerfile (`Dockerfile.phpmyadmin`) with several optimizations:

- Added proper PHP-FPM user/group settings (`user = nginx` and `group = nginx`)
- Improved configuration files with proper newlines using `echo -e`
- Used Alpine as the base image for reduced size
- Multi-stage build for minimal image size

### phpMyAdmin Environment Variables

| Variable | Description | Default Value |
|----------|-------------|---------------|
| PMA_HOST | Database hostname | mariadb |
| PMA_USER | Database username | wordpress |
| PMA_PASSWORD | Database password | wordpress |

## MariaDB Configuration

The MariaDB container uses the official MariaDB image with these configurations:

- Used official MariaDB image for compatibility
- Ensured proper volume setup for data persistence

### MariaDB Environment Variables

| Variable | Description | Default Value |
|----------|-------------|---------------|
| MYSQL_ROOT_PASSWORD | Root password | wordpress |
| MYSQL_DATABASE | Database name | wordpress |
| MYSQL_USER | Database user | wordpress |
| MYSQL_PASSWORD | Database password | wordpress |

## Redis Configuration

The Redis containers use the official Redis Alpine-based image with several optimizations:

- Used official Redis Alpine-based image (7.2-alpine) for reduced size and optimized performance
- Configured password authentication for security
- Set up volumes for data persistence (separate volume for each Redis instance)
- Integrated with WordPress via environment variables
- Multiple Redis instances (redis-1 and redis-2) for better resource distribution
- Different port mappings for each Redis instance (6379 and 6380)

### Redis Command Arguments

```
redis-server --requirepass wordpress_redis
```

For enhanced production configurations, consider adding:
```
--maxmemory 256mb --maxmemory-policy allkeys-lru
```

## SSL Configuration

The HTTPS support is configured with:

1. Self-signed certificates generated using the included `generate-ssl-certs.sh` script
2. SSL certificates stored in the `./nginx/ssl/` directory
3. HTTPS enabled by default with the proper configuration in `./nginx/default.conf`
4. Automatic HTTP to HTTPS redirection
5. Modern SSL protocols (TLSv1.2 and TLSv1.3) with secure cipher configurations

To regenerate SSL certificates:

```bash
../generate-ssl-certs.sh
```

## Network Configuration

The services communicate through a custom bridge network:

```yaml
networks:
  wp_network:
    driver: bridge
```

This provides:
- Internal DNS resolution using service names
- Isolated network environment
- Network-level security

## Volume Configuration

The setup uses named volumes for data persistence:

```yaml
volumes:
  db_data:           # MariaDB data
  redis_data_1:      # Redis instance 1 data
  redis_data_2:      # Redis instance 2 data
  wordpress_uploads: # Shared WordPress uploads
```

## Docker Compose Configuration Reference

For the complete Docker Compose configuration, refer to the [`compose.yaml`](../compose.yaml) file in the project root directory.

## Custom Scripts

The project includes several utility scripts:

- `../create-wp-config.sh`: Configures WordPress to work with Redis
- `../install-redis-plugin.sh`: Installs and activates the Redis Object Cache plugin
- `../generate-ssl-certs.sh`: Generates self-signed SSL certificates
- `../test-wordpress.sh`: Tests connectivity between all services

## Additional Configuration Options

To further customize the setup, consider modifying:

1. PHP configuration in the WordPress container
2. MariaDB configuration options
3. Redis memory settings
4. NGINX caching parameters
5. WordPress optimization plugins

See the [OPTIMIZATION.md](./OPTIMIZATION.md) and [SCALING.md](./SCALING.md) files for specific configuration improvements for high-traffic scenarios.

## Architecture Overview

The architecture for this setup is detailed in the [Architecture](docs/ARCHITECTURE.md) document. It includes:

- High-level component diagram
- Service interaction flow
- Deployment topology

Review the architecture document to understand the overall system design and how each component fits into the WordPress, MariaDB, and Redis ecosystem.
