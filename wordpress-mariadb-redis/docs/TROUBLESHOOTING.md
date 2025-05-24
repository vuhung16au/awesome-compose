# Troubleshooting

This document covers common issues you might encounter with the WordPress, MariaDB, and Redis setup and provides solutions to resolve them.

## Automated Diagnostics

This project includes a connectivity testing script that automates the process of checking all services:

```bash
../test-wordpress.sh
```

The script performs comprehensive checks including:

- WordPress, phpMyAdmin, MariaDB, NGINX, and Redis connectivity
- NGINX load balancing configuration and functionality
- PHP Redis module verification
- Redis Object Cache plugin installation
- NGINX, Apache, and PHP error log inspection
- WordPress configuration validation

Running this script is recommended as the first step when troubleshooting any issues.

## Common Issues

### NGINX Connection Issues

If you can't connect to WordPress through NGINX:

1. Check that both NGINX and WordPress containers are running
   ```bash
   docker ps | grep -E "nginx|wordpress"
   ```

2. Verify that port 80 is not used by another application
   ```bash
   lsof -i :80
   ```

3. Examine NGINX logs
   ```bash
   docker logs wordpress-mariadb-redis-nginx-1
   ```

4. Ensure the WordPress service is working by checking container logs
   ```bash
   docker logs wordpress-mariadb-redis-wordpress-1-1
   ```

### Database Connection Error

If WordPress cannot connect to the database:

1. Check that the MariaDB container is running
   ```bash
   docker ps | grep mariadb
   ```

2. Verify the environment variables in both containers match
   ```bash
   docker exec wordpress-mariadb-redis-wordpress-1-1 env | grep WORDPRESS_DB
   docker exec wordpress-mariadb-redis-mariadb-1 env | grep MYSQL
   ```

3. Try restarting both services
   ```bash
   docker restart wordpress-mariadb-redis-mariadb-1
   docker restart wordpress-mariadb-redis-wordpress-1-1
   ```

4. Check MariaDB logs for any errors
   ```bash
   docker logs wordpress-mariadb-redis-mariadb-1
   ```

### phpMyAdmin Connection Issues

If you cannot access phpMyAdmin or it cannot connect to MariaDB:

1. Ensure the `mariadb` service is running
   ```bash
   docker ps | grep mariadb
   ```

2. Check that port 8080 is not being used by another application
   ```bash
   lsof -i :8080
   ```

3. Verify the environment variables match those used by MariaDB
   ```bash
   docker exec wordpress-mariadb-redis-phpmyadmin-1 env | grep PMA
   ```

4. Check phpMyAdmin container logs
   ```bash
   docker logs wordpress-mariadb-redis-phpmyadmin-1
   ```

### Persistence Issues

If your data disappears after restarts:

1. Make sure you're not using `down -v` which removes volumes
2. Check that volumes are properly configured in your compose file
3. Verify that volumes exist and are mounted correctly
   ```bash
   docker volume ls | grep wordpress
   ```
4. Inspect a specific volume
   ```bash
   docker volume inspect db_data
   ```

### Redis Connection Issues

If WordPress can't connect to Redis:

1. Verify the Redis service is running
   ```bash
   docker ps | grep redis
   ```

2. Check that the Redis password in WordPress configuration matches the one in the Redis command
   ```bash
   docker exec wordpress-mariadb-redis-wordpress-1-1 env | grep REDIS
   ```

3. Ensure the Redis Object Cache plugin is properly activated
   ```bash
   docker exec wordpress-mariadb-redis-wordpress-1-1 wp plugin list | grep redis
   ```

4. Check the Redis logs
   ```bash
   docker logs wordpress-mariadb-redis-redis-1-1
   ```

5. Test Redis connectivity from within the WordPress container
   ```bash
   docker exec wordpress-mariadb-redis-wordpress-1-1 redis-cli -h redis-1 -a wordpress_redis ping
   ```

### SSL/HTTPS Issues

If you're experiencing issues with HTTPS:

1. Check that the SSL certificates are properly generated
   ```bash
   ls -la nginx/ssl/
   ```

2. If certificates are missing, run the certificate generation script
   ```bash
   ../generate-ssl-certs.sh
   ```

3. Verify NGINX SSL configuration
   ```bash
   docker exec wordpress-mariadb-redis-nginx-1 nginx -t
   ```

4. Restart NGINX after making changes
   ```bash
   docker restart wordpress-mariadb-redis-nginx-1
   ```

### WordPress Plugin Issues

If Redis Object Cache plugin is not working:

1. Check if the plugin is properly installed
   ```bash
   docker exec wordpress-mariadb-redis-wordpress-1-1 ls -la /var/www/html/wp-content/plugins/
   ```

2. Reinstall the Redis Object Cache plugin if needed
   ```bash
   docker exec wordpress-mariadb-redis-wordpress-1-1 /install-redis-plugin.sh
   ```

3. Verify that PHP Redis extension is installed
   ```bash
   docker exec wordpress-mariadb-redis-wordpress-1-1 php -m | grep redis
   ```

## Prometheus and Grafana Troubleshooting

If you cannot access Prometheus or Grafana:

1. Ensure the containers are running:
   ```bash
   docker ps | grep -E "prometheus|grafana"
   ```
2. Check that ports 9090 (Prometheus) and 3000 (Grafana) are not used by other applications:
   ```bash
   lsof -i :9090
   lsof -i :3000
   ```
3. View container logs for errors:
   ```bash
   docker compose logs prometheus
   docker compose logs grafana
   ```
4. For Grafana, ensure Prometheus is added as a data source and dashboards are imported.
5. For Prometheus, check the 'Targets' page at http://localhost:9090/targets to verify all exporters are UP.

## Security Considerations

The configuration provided is intended for local development only. For production environments:

- Use strong, unique passwords (see `.env` for current values)
- Consider using Docker secrets for sensitive information
- Implement proper network segmentation
- Enable SSL/TLS for secure connections

## Viewing Container Logs

For general debugging, you can view logs from any container:

```bash
# View logs for a specific container
docker logs <container_name>

# Follow logs in real-time
docker logs -f <container_name>

# Show the last N lines of logs
docker logs --tail=100 <container_name>
```

Replace `<container_name>` with the appropriate container name from `docker ps` output.
