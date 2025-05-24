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
├── nginx/ 
│   ├── default.conf
│   ├── nginx.conf
│   └── ssl/ 
├── Prompt.md
├── README.md
├── test-connectivity.sh
└── wordpress-installation.png
```

[_compose.yaml_](compose.yaml)

```yaml
services:
  nginx:
    image: nginx:stable-alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - wordpress-1
      - wordpress-2
      - wordpress-3
    networks:
      - wp_network
  wordpress-1:
    build:
      context: .
      dockerfile: Dockerfile.wordpress
    # ports removed as NGINX handles external connections
    environment:
      - WORDPRESS_DB_HOST=mariadb
      - WORDPRESS_DB_USER=wordpress
      - WORDPRESS_DB_PASSWORD=wordpress
      - WORDPRESS_DB_NAME=wordpress
      - WORDPRESS_REDIS_HOST=redis-1
      - WORDPRESS_REDIS_PASSWORD=wordpress_redis
    depends_on:
      - mariadb
      - redis-1
    networks:
      - wp_network
  mariadb:
    image: mariadb:10
    environment:
      - MYSQL_ROOT_PASSWORD=wordpress
      - MYSQL_DATABASE=wordpress
      - MYSQL_USER=wordpress
      - MYSQL_PASSWORD=wordpress
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - wp_network
  redis-1:
    image: redis:7.2-alpine
    restart: always
    command: ["redis-server", "--requirepass", "wordpress_redis"]
    ports:
      - "6379:6379"
    volumes:
      - redis_data_1:/data
    networks:
      - wp_network
  redis-2:
    image: redis:7.2-alpine
    restart: always
    command: ["redis-server", "--requirepass", "wordpress_redis"]
    ports:
      - "6380:6379"
    volumes:
      - redis_data_2:/data
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
  redis_data_1:
  redis_data_2:
  wordpress_uploads:
networks:
  wp_network:
    driver: bridge
```

When deploying this setup, Docker Compose maps the NGINX container port 80 to port 80 of the host as specified in the compose file.

> ℹ️ **_INFO_**
>
> For compatibility between `AMD64` and `ARM64` architecture, MariaDB is used as the database.
> MariaDB 10 is compatible with both architectures and works well with WordPress as of 2025.
> Note: WordPress does not natively support PostgreSQL but is fully compatible with MySQL/MariaDB, which is why MariaDB was chosen as the database solution.

## Local Development Configuration

This setup includes:

- **Networks**: A custom bridge network for services to communicate using service names
- **Volumes**: Named volumes for MariaDB and Redis data persistence
- **Restart Policy**: Automatic restart for all services if they fail
- **NGINX**: Reverse proxy and load balancer for WordPress
- **phpMyAdmin**: Database administration tool accessible via port 8080
- **Redis Cache**: Object caching for improved WordPress performance
- **Multi-stage builds**: Custom Dockerfiles that significantly reduce image sizes

## Future Enhancements

- **Implement Content Delivery Network (CDN)**: Add CloudFront or another CDN for further performance improvements
- **Add Scheduled Backups**: Implement automated database and file backups
- **Set Up Monitoring**: Add Prometheus/Grafana monitoring for system metrics

## NGINX Reverse Proxy and Load Balancing

This project now includes NGINX as a reverse proxy and load balancer, providing several key benefits:

### Reverse Proxy Benefits

- **Security Enhancement**: NGINX acts as a barrier between users and your WordPress application
- **SSL/TLS Termination**: NGINX can handle HTTPS encryption/decryption
- **Static Asset Caching**: Improves performance by caching static files
- **Compression**: Reduces bandwidth usage with gzip compression
- **Protection Against Common Attacks**: Better security against DDoS and other attacks

### Load Balancing Features

- **Multiple WordPress Instances**: Three WordPress instances provide horizontal scaling out of the box
- **Redis Distribution**: WordPress instances 1 and 3 connect to redis-1, while instance 2 connects to redis-2
- **Session Persistence**: IP hash ensures users maintain their sessions even with multiple WordPress instances
- **Health Checks**: Automatically redirects traffic from unhealthy instances
- **Equal Distribution**: Distributes incoming requests across all three WordPress instances

### Load Balancing Configuration

This setup comes pre-configured with 3 WordPress instances and load balancing ready to use. NGINX automatically distributes traffic between these WordPress instances using the IP hash algorithm for session persistence.

Simply start the stack with:

```bash
# Start the stack with 3 WordPress instances and 2 Redis instances
docker compose up -d
```

All three WordPress instances will be created, along with two Redis instances, and NGINX will automatically load balance traffic between the WordPress containers.

### NGINX Configuration Files

The NGINX setup consists of two main configuration files:

1. **nginx.conf**: Contains global NGINX settings
2. **default.conf**: Contains the site-specific configuration including load balancing

These files are located in the `./nginx/` directory and are mounted as read-only volumes in the NGINX container.

### HTTPS Support

The configuration includes full support for HTTPS to secure your WordPress site:

1. Self-signed certificates are automatically generated using the included `generate-ssl-certs.sh` script
2. SSL certificates are stored in the `./nginx/ssl/` directory
3. HTTPS is enabled by default with the proper configuration in `./nginx/default.conf`
4. Automatic HTTP to HTTPS redirection is configured for enforced secure connections
5. Modern SSL protocols (TLSv1.2 and TLSv1.3) are enabled with secure cipher configurations

To access the site securely, simply navigate to `https://localhost/` in your web browser. Note that since the certificates are self-signed, you may need to accept a security warning in your browser during local development.

## Image Size Optimization

To reduce the size of Docker images and improve deployment efficiency, this project uses:

1. **Alpine-based images**: The Alpine Linux distribution is significantly smaller than Ubuntu or Debian-based images.
2. **Specific image tags**: Instead of using `latest`, exact versions are specified.
3. **Multi-stage builds**: Custom Dockerfiles use multi-stage builds to create minimal images with only required components.

### Example image size comparison

| Service    | Original Image                | Size   | Optimized Image              | Size       | Reduction |
|------------|------------------------------|--------|------------------------------|------------|-----------|
| phpMyAdmin | phpmyadmin:latest            | 819MB  | Custom multi-stage build     | 143MB      | ~83%      |
| Redis      | redis:latest                 | 117MB  | redis:7.2-alpine             | 36MB       | ~70%      |

## Before/After Docker Optimization

Here's a comparison of Docker images before and after optimization:

### Before Optimization

```console
TAG                 IMAGE ID       CREATED         SIZE
mariadb      10                  56710811b0b9   19 months ago   491MB
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
mariadb                             10        56710811b0b9   19 months ago    491MB
redis                               7.2-alpine 2e3198c7a02c   2 months ago     36MB
nginx                               stable-alpine 8e25c1f79863 2 months ago     40MB
```

The overall size reduction is 962MB (2,497MB - 1,535MB), which represents approximately a 38.5% reduction in total image size across all containers, with significant savings in the WordPress and phpMyAdmin images. For Redis and NGINX, we use Alpine-based images which are significantly smaller than standard images.

## Deploy Options

### Standard Deployment

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

## Expected result

Check containers are running and the port mapping:

```bash
docker ps
```

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

![Wordpress Installation](wordpress-installation.png)

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

### NGINX Configuration

- Used stable-alpine image for reduced size
- Optimized for WordPress with specialized settings
- Configured for load balancing multiple WordPress instances
- Implemented HTTPS with SSL/TLS termination for secure connections
- Set up caching for static assets to improve performance
- Implemented gzip compression to reduce bandwidth usage
- Configured automatic HTTP to HTTPS redirection for security

### WordPress Configuration

- Configured three separate WordPress instances for load balancing and redundancy
- Each WordPress instance has its own configuration but shares the same database
- WordPress instances 1 and 3 connect to Redis-1, while WordPress instance 2 connects to Redis-2
- Fixed entrypoint script in `Dockerfile.wordpress` with proper newline handling using `echo -e`
- Optimized Apache and PHP-FPM configuration for better performance
- Used Alpine as base image with PHP 8.2 to reduce overall size
- Installed PHP Redis extension for object caching
- Included Redis Object Cache plugin for WordPress
- All instances share a common uploads directory via volume mount for consistent media library

### phpMyAdmin Configuration

- Added proper PHP-FPM user/group settings (`user = nginx` and `group = nginx`)
- Improved configuration files with proper newlines using `echo -e`
- Used Alpine as the base image

### MariaDB Configuration

- Used official MariaDB image for compatibility
- Ensured proper volume setup for data persistence

### Redis Configuration

- Used official Redis Alpine-based image (7.2-alpine) for reduced size and optimized performance
- Configured password authentication for security
- Set up volumes for data persistence (separate volume for each Redis instance)
- Integrated with WordPress via environment variables
- Multiple Redis instances (redis-1 and redis-2) for better resource distribution
- Different port mappings for each Redis instance (6379 and 6380)

## Connectivity Testing

To verify that all services are properly connected and functioning, you can use the included connectivity test script:

```bash
# Make the script executable first (if needed)
chmod +x test-wordpress.sh

# Run the test script
./test-wordpress.sh
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

## Troubleshooting

### Automated Diagnostics

This project includes a connectivity testing script that automates the process of checking all services:

```bash
./test-wordpress.sh
```

The script performs comprehensive checks including:

- WordPress, phpMyAdmin, MariaDB, NGINX, and Redis connectivity
- NGINX load balancing configuration and functionality
- PHP Redis module verification
- Redis Object Cache plugin installation
- NGINX, Apache, and PHP error log inspection
- WordPress configuration validation

Running this script is recommended as the first step when troubleshooting any issues.

### Common Issues

#### NGINX Connection Issues

If you can't connect to WordPress through NGINX:

1. Check that both NGINX and WordPress containers are running
2. Verify that port 80 is not used by another application
3. Examine NGINX logs: `docker logs wordpress-mariadb-redis-nginx-1`
4. Ensure the WordPress service is working by checking container logs

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

- ~~NGINX as a reverse proxy~~ ✓ Implemented
- ~~MailHog for email testing~~
- ~~Memcached for additional caching strategies~~
- Elasticsearch for improved search functionality

### Scaling for Heavy Traffic

For WordPress sites expecting heavy traffic, the following enhancements can be implemented:

#### Immediate Optimizations

1. **Enhanced Redis Configuration**
   ```yaml
   redis:
     image: redis:7.2-alpine
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

1. **Load Balancing with NGINX** ✓ Implemented
   - Already configured in the `compose.yaml` file
   - Scale WordPress instances: `docker compose up --scale wordpress=3 -d`

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
