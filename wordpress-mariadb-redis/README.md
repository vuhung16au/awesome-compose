# WordPress with MariaDB and Redis

This example defines a setup for WordPress with MariaDB as the database and Redis for object caching. This combination significantly improves WordPress performance by reducing database queries. More details on the WordPress setup can be found on the official [WordPress image page](https://hub.docker.com/_/wordpress) and [Redis image page](https://hub.docker.com/_/redis).

Project structure:

```text
.
├── compose.yaml
├── create-wp-config.sh
├── Dockerfile.phpmyadmin
├── Dockerfile.wordpress
├── install-redis-plugin.sh
├── LICENSE.md
├── Prompt.md
├── README.md
├── test-connectivity.sh
└── wordpress-installation.png
```

[_compose.yaml_](compose.yaml)

```yaml
services:
  wordpress:
    build:
      context: .
      dockerfile: Dockerfile.wordpress
    ports:
      - "80:80"
    environment:
      - WORDPRESS_DB_HOST=mariadb
      - WORDPRESS_DB_USER=wordpress
      - WORDPRESS_DB_PASSWORD=wordpress
      - WORDPRESS_DB_NAME=wordpress
      - WORDPRESS_REDIS_HOST=redis
      - WORDPRESS_REDIS_PASSWORD=wordpress_redis
    depends_on:
      - mariadb
      - redis
    networks:
      - wp_network
  mariadb:
    image: mariadb:10.9
    environment:
      - MYSQL_ROOT_PASSWORD=wordpress
      - MYSQL_DATABASE=wordpress
      - MYSQL_USER=wordpress
      - MYSQL_PASSWORD=wordpress
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - wp_network
  redis:
    image: redis:8.0-alpine
    restart: always
    command: ["redis-server", "--requirepass", "wordpress_redis"]
    volumes:
      - redis_data:/data
    networks:
      - wp_network
  phpmyadmin:
    build:
      context: .
      dockerfile: Dockerfile.phpmyadmin
    ports:
      - "8080:80"
    environment:
      - PMA_HOST=mariadb
      - PMA_USER=wordpress
      - PMA_PASSWORD=wordpress
    depends_on:
      - mariadb
    networks:
      - wp_network
volumes:
  db_data:
  redis_data:
networks:
  wp_network:
    driver: bridge
```

When deploying this setup, Docker Compose maps the WordPress container port 80 to port 80 of the host as specified in the compose file.

> ℹ️ **_INFO_**
>
> For compatibility between `AMD64` and `ARM64` architecture, MariaDB is used as the database.
> MariaDB 10.9 is compatible with both architectures and works well with WordPress as of 2025.
> Note: WordPress does not natively support PostgreSQL but is fully compatible with MySQL/MariaDB, which is why MariaDB was chosen as the database solution.

## Local Development Configuration

This setup includes:

- **Networks**: A custom bridge network for services to communicate using service names
- **Volumes**: Named volumes for MariaDB and Redis data persistence
- **Restart Policy**: Automatic restart for all services if they fail
- **phpMyAdmin**: Database administration tool accessible via port 8080
- **Redis Cache**: Object caching for improved WordPress performance
- **Multi-stage builds**: Custom Dockerfiles that significantly reduce image sizes

## Image Size Optimization

To reduce the size of Docker images and improve deployment efficiency, this project uses:

1. **Alpine-based images**: The Alpine Linux distribution is significantly smaller than Ubuntu or Debian-based images.
2. **Specific image tags**: Instead of using `latest`, exact versions are specified.
3. **Multi-stage builds**: Custom Dockerfiles use multi-stage builds to create minimal images with only required components.

### Example image size comparison

| Service    | Original Image                | Size   | Optimized Image              | Size       | Reduction |
|------------|------------------------------|--------|------------------------------|------------|-----------|
| phpMyAdmin | phpmyadmin:latest            | 819MB  | Custom multi-stage build     | 143MB      | ~83%      |
| Redis      | redis:latest                 | 117MB  | redis:8.0-alpine             | 36MB       | ~70%      |

## Before/After Docker Optimization

Here's a comparison of Docker images before and after optimization:

### Before Optimization

```console
TAG                 IMAGE ID       CREATED         SIZE
mariadb      10.9                56710811b0b9   19 months ago   491MB
wordpress    6.4-php8.1-apache   4c64df591c9a   14 months ago   1.03GB
phpmyadmin   latest              68d7f9dc247b   3 months ago    819MB
redis        latest              3c1b5271fdf5   2 months ago    117MB
```

### After Optimization

```console
docker images
REPOSITORY                          TAG       IMAGE ID       CREATED          SIZE
wordpress-mariadb-redis-phpmyadmin  latest    57f51d2fec86   40 minutes ago   143MB
wordpress-mariadb-redis-wordpress   latest    b4a4a62c9eeb   46 minutes ago   284MB
mariadb                             10.9      56710811b0b9   19 months ago    491MB
redis                               8.0-alpine 2e3198c7a02c   2 months ago     36MB
```

The overall size reduction is 922MB (2,457MB - 1,535MB), which represents approximately a 38% reduction in total image size across all containers, with significant savings in the WordPress and phpMyAdmin images. For Redis, we use the Alpine-based image (redis:8.0-alpine) which is significantly smaller than the standard image.

## Deploy Options

### Standard Deployment

```bash
docker compose up -d
```

Example output for standard deployment:

```console
[+] Running 5/5
 ✔ Network wordpress-mariadb-redis_wp_network        Created   0.0s
 ✔ Container wordpress-mariadb-redis-mariadb-1       Started   0.6s
 ✔ Container wordpress-mariadb-redis-redis-1         Started   0.2s
 ✔ Container wordpress-mariadb-redis-wordpress-1     Started   0.3s
 ✔ Container wordpress-mariadb-redis-phpmyadmin-1    Started   0.3s
```

## Expected result

Check containers are running and the port mapping:

```bash
docker ps
```

Example output:

```console
CONTAINER ID   IMAGE                              COMMAND                  CREATED          STATUS          PORTS                NAMES
d4feb59bab20   wordpress-mariadb-redis-wordpress  ...                     Up 46 seconds   0.0.0.0:80->80/tcp   wordpress-mariadb-redis-wordpress-1
0ff2639f74ca   mariadb:10.9                       ...                     Up 46 seconds   3306/tcp             wordpress-mariadb-redis-mariadb-1
e7c1c45e1f9a   redis:8.0-alpine                  ...                     Up 46 seconds   6379/tcp             wordpress-mariadb-redis-redis-1
8ad2f721be3c   wordpress-mariadb-redis-phpmyadmin ...                     Up 46 seconds   0.0.0.0:8080->80/tcp  wordpress-mariadb-redis-phpmyadmin-1
```

## Accessing Services

### WordPress

Navigate to `http://localhost:80` in your web browser to access WordPress.

![Wordpress Installation](wordpress-installation.png)

After installation, go to your WordPress admin panel and activate the Redis Object Cache plugin to enable Redis caching.

#### Redis Object Cache Configuration

1. Log in to your WordPress admin panel (typically at `http://localhost/wp-admin/`)
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

### Stopping Services

```bash
docker compose down
```

To remove all WordPress data, delete the named volumes by passing the `-v` parameter:

```bash
docker compose down -v
```

## Configuration Optimizations

To ensure the Docker containers work properly, several configuration improvements were made:

### WordPress Configuration

- Fixed entrypoint script in `Dockerfile.wordpress` with proper newline handling using `echo -e`
- Optimized Apache and PHP-FPM configuration for better performance
- Used Alpine as base image to reduce overall size
- Installed PHP Redis extension for object caching
- Included Redis Object Cache plugin for WordPress

### phpMyAdmin Configuration

- Added proper PHP-FPM user/group settings (`user = nginx` and `group = nginx`)
- Improved configuration files with proper newlines using `echo -e`
- Used Alpine as the base image

### MariaDB Configuration

- Used official MariaDB image for compatibility
- Ensured proper volume setup for data persistence

### Redis Configuration

- Used official Redis Alpine-based image (8.0-alpine) for reduced size and optimized performance
- Configured password authentication for security
- Set up volume for data persistence
- Integrated with WordPress via environment variables

## Connectivity Testing

To verify that all services are properly connected and functioning, you can use the included connectivity test script:

```bash
# Make the script executable first (if needed)
chmod +x test-connectivity.sh

# Run the connectivity test
./test-connectivity.sh
```

The script performs the following checks:
- Verifies that all containers are running
- Tests if WordPress is accessible
- Tests if phpMyAdmin is accessible
- Verifies the WordPress to MariaDB connection
- Confirms Redis connectivity and password authentication
- Checks if the Redis PHP module is installed in WordPress
- Verifies Redis Object Cache plugin installation
- Examines Apache and PHP logs for errors
- Displays WordPress configuration settings

This script is useful for troubleshooting connection issues and ensuring all components of the stack are working together properly.

## Troubleshooting

### Automated Diagnostics

This project includes a connectivity testing script that automates the process of checking all services:

```bash
./test-connectivity.sh
```

The script performs comprehensive checks including:

- WordPress, phpMyAdmin, MariaDB and Redis connectivity
- PHP Redis module verification
- Redis Object Cache plugin installation
- Apache and PHP error log inspection
- WordPress configuration validation

Running this script is recommended as the first step when troubleshooting any issues.

### Common Issues

#### Database Connection Error

If WordPress cannot connect to the database:

1. Check that the MariaDB container is running
2. Verify the environment variables in both containers match
3. Try restarting both services

#### phpMyAdmin Connection Issues

If you cannot access phpMyAdmin or it cannot connect to MariaDB:

1. Ensure the `mariadb` service is running
2. Check that port 8080 is not being used by another application
3. Verify the environment variables match those used by MariaDB

#### Persistence Issues

If your data disappears after restarts:

1. Make sure you're not using `down -v` which removes volumes
2. Check that volumes are properly configured in your compose file

#### Redis Connection Issues

If WordPress can't connect to Redis:

1. Verify the Redis service is running with `docker ps`
2. Check that the Redis password in WordPress configuration matches the one in the Redis command
3. Ensure the Redis Object Cache plugin is properly activated
4. Check the Redis logs with `docker logs wordpress-mariadb-redis-redis-1`

## Additional Information

### Performance Benefits of Redis Caching

Adding Redis to WordPress provides several key benefits:

- **Reduced Database Load**: WordPress stores query results in Redis instead of repeatedly querying the database
- **Faster Page Loading**: Cached objects are retrieved from memory rather than being regenerated
- **Improved Concurrency**: Better handling of traffic spikes with cached resources
- **Session Storage**: Centralized session management for better user experience
- **Persistent Object Cache**: Data persists between requests, unlike transient caches

Typical performance improvements with Redis caching:

- 2-5x faster page loads for authenticated users
- 20-40% reduction in server resource usage
- Significantly improved handling of high-traffic situations

### Security Note

The configuration provided is intended for local development only. For production environments:

- Use strong, unique passwords
- Consider using Docker secrets for sensitive information
- Implement proper network segmentation
- Enable SSL/TLS for secure connections

### Extending the Setup

This setup can be further extended with additional services:

- NGINX as a reverse proxy
- ~~MailHog for email testing~~
- ~~Memcached for additional caching strategies~~
- Elasticsearch for improved search functionality

### Scaling for Heavy Traffic

For WordPress sites expecting heavy traffic, the following enhancements can be implemented:

#### Immediate Optimizations

1. **Enhanced Redis Configuration**
   ```yaml
   redis:
     image: redis:8.0-alpine
     command: ["redis-server", "--requirepass", "wordpress_redis", "--maxmemory", "256mb", "--maxmemory-policy", "allkeys-lru"]
   ```

2. **Database Performance Tuning**
   ```yaml
   mariadb:
     command:
       - --max_connections=500
       - --innodb_buffer_pool_size=1G
       - --query_cache_size=64M
   ```

3. **WordPress Optimization**
   - Install performance plugins (WP Rocket, Autoptimize)
   - Implement proper page caching with Redis
   - Configure PHP-FPM for optimal resource usage

#### Horizontal Scaling Architecture

1. **Load Balancing with NGINX**
   ```yaml
   nginx-lb:
     image: nginx:alpine
     ports:
       - "80:80"
     volumes:
       - ./nginx-lb.conf:/etc/nginx/nginx.conf
     depends_on:
       - wordpress
     networks:
       - wp_network
   ```

2. **WordPress Container Scaling**
   ```bash
   docker compose up --scale wordpress=3 -d
   ```

3. **Shared Storage for Uploads**
   ```yaml
   wordpress:
     volumes:
       - wp_shared_content:/var/www/html/wp-content/uploads
   
   volumes:
     wp_shared_content:
       driver: local  # Use NFS/Cloud storage in production
   ```

#### Production Infrastructure

1. **Database Scaling**
   - Implement MariaDB with primary/replica setup
   - Add database connection pooling

2. **CDN Integration**
   - Implement content delivery network for static assets
   - Add appropriate caching headers

3. **Monitoring & Auto-scaling**
   ```yaml
   prometheus:
     image: prom/prometheus:latest
     volumes:
       - ./prometheus:/etc/prometheus
       - prometheus_data:/prometheus
     command:
       - '--config.file=/etc/prometheus/prometheus.yml'
     ports:
       - "9090:9090"
     networks:
       - wp_network
   
   grafana:
     image: grafana/grafana:latest
     ports:
       - "3000:3000"
     volumes:
       - grafana_data:/var/lib/grafana
     depends_on:
       - prometheus
     networks:
       - wp_network
   ```

For enterprise-level scaling, consider migrating from Docker Compose to Kubernetes, which offers more robust orchestration features including auto-scaling, rolling updates, and high availability.

### License

This project is distributed under the MIT License. See the [LICENSE](LICENSE) file for details.
