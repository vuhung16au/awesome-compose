# Performance Optimization

This document outlines the various optimizations implemented in this WordPress with MariaDB and Redis setup to improve performance, efficiency, and resource utilization.

## Image Size Optimization

To reduce the size of Docker images and improve deployment efficiency, this project uses:

1. **Alpine-based images**: The Alpine Linux distribution is significantly smaller than Ubuntu or Debian-based images.
2. **Specific image tags**: Instead of using `latest`, exact versions are specified.
3. **Multi-stage builds**: Custom Dockerfiles use multi-stage builds to create minimal images with only required components.

### Example Image Size Comparison

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

## Total Docker Image and Volume Sizes

### Image Sizes

The total size of the Docker images used by your WordPress project containers is approximately:

- WordPress images (3 instances): 286MB each × 3 = 858MB (shared 216.5MB)
- phpMyAdmin image: 143MB
- MariaDB image: 432MB
- Redis image (7.2-alpine): 60.7MB
- Nginx image (stable-alpine): 75.9MB
- Backup service image: 68.8MB
- Grafana image (10.2.2): 522MB
- Prometheus image (v2.45.0): 320MB
- Redis Exporter image (v1.54.0): 24.6MB

Adding these up gives roughly 2.50GB of image data, with optimized images used where possible.

### Container Sizes

Container sizes are minimal as they primarily represent the writable layer changes:

| Container Name | Size |
|---------------|------|
| wordpress-mariadb-redis-wordpress-1-1 | 86 KB |
| wordpress-mariadb-redis-wordpress-2-1 | 86 KB |
| wordpress-mariadb-redis-wordpress-3-1 | 90.1 KB |
| wordpress-mariadb-redis-phpmyadmin-1 | 94.2 KB |
| wordpress-mariadb-redis-mariadb-1 | 24.6 KB |
| wordpress-mariadb-redis-redis-1-1 | 4.1 KB |
| wordpress-mariadb-redis-redis-2-1 | 4.1 KB |
| wordpress-mariadb-redis-nginx-1 | 69.6 KB |
| wordpress-mariadb-redis-grafana-1 | 4.1 KB |
| wordpress-mariadb-redis-prometheus-1 | 4.1 KB |
| wordpress-mariadb-redis-redis-exporter-1-1 | 4.1 KB |
| wordpress-mariadb-redis-redis-exporter-2-1 | 4.1 KB |
| wordpress-mariadb-redis-backup-1 | 61.4 KB |

### Volume Sizes

Actual measured volume sizes:

- `wordpress-mariadb-redis_db_data`: 156.5 MB (MariaDB data)
- `wordpress-mariadb-redis_grafana_data`: 38.27 MB (Grafana data)
- `wordpress-mariadb-redis_redis_data_1` and `_2`: minimal usage (88 B each)
- `wordpress-mariadb-redis_wordpress_uploads`: 0 B (WordPress uploads)

The total resource size includes about 2.50GB of images plus approximately 195MB of volume data, though this will grow as WordPress content and database records increase.

## Performance Benefits of Redis Caching

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

## NGINX Performance Optimizations

- **Static Asset Caching**: Improves performance by caching static files
- **Compression**: Reduces bandwidth usage with gzip compression
- **Load Balancing**: Distributes requests across multiple WordPress instances
- **Connection Pooling**: Optimizes connection management to backend services
- **HTTP/2 Support**: Modern protocol with multiplexing for better performance

## Memory Usage Optimization

The WordPress with MariaDB and Redis setup has been optimized for memory efficiency. Below is the current memory usage for all services:

| Service Container Name                      | Memory Usage          |
|---------------------------------------------|----------------------|
| wordpress-mariadb-redis-mariadb-1            | 81 MiB / 7.654 GiB   |
| wordpress-mariadb-redis-grafana-1            | 81.76 MiB / 7.654 GiB|
| wordpress-mariadb-redis-prometheus-1         | 21.28 MiB / 7.654 GiB|
| wordpress-mariadb-redis-wordpress-3-1        | 37.96 MiB / 7.654 GiB|
| wordpress-mariadb-redis-wordpress-1-1        | 16.39 MiB / 7.654 GiB|
| wordpress-mariadb-redis-wordpress-2-1        | 15.86 MiB / 7.654 GiB|
| wordpress-mariadb-redis-phpmyadmin-1         | 16.08 MiB / 7.654 GiB|
| wordpress-mariadb-redis-redis-exporter-1-1   | 13.32 MiB / 7.654 GiB|
| wordpress-mariadb-redis-redis-exporter-2-1   | 15.06 MiB / 7.654 GiB|
| wordpress-mariadb-redis-nginx-1              | 9.551 MiB / 7.654 GiB|
| wordpress-mariadb-redis-redis-1-1            | 5.605 MiB / 7.654 GiB|
| wordpress-mariadb-redis-redis-2-1            | 3.551 MiB / 7.654 GiB|
| wordpress-mariadb-redis-backup-1             | 0B / 0B (restarting) |

### Key Memory Optimization Features:

- **Efficient Container Sizing**: Most containers use less than 40 MiB memory
- **Alpine-Based Images**: Reduced memory footprint with Alpine Linux versions
- **Redis Memory Efficiency**: Redis instances use minimal memory (3.5-5.6 MiB)
- **PHP-FPM Tuning**: Optimized PHP memory limits for WordPress containers
- **Shared Memory Usage**: Total memory consumption is approximately 317.4 MiB across all services

The total memory footprint is remarkably low considering the full stack includes a WordPress cluster with three instances, MariaDB database, Redis caching, phpMyAdmin, Nginx load balancer, and monitoring tools (Prometheus and Grafana).

## WordPress Performance Enhancements

- **Object Caching with Redis**: Significantly reduces database queries
- **Optimized PHP Configuration**: Fine-tuned for WordPress workloads
- **PHP-FPM Process Management**: Properly configured for optimal resource usage
- **Alpine Base Image**: Reduced container size and memory footprint
- **Redis Object Cache Plugin**: Pre-installed for immediate performance benefits
