# WordPress with MariaDB and Redis

This example defines a setup for WordPress with MariaDB as the database and Redis for object caching. This combination significantly improves WordPress performance by reducing database queries. More details on the WordPress setup can be found on the official [WordPress image page](https://hub.docker.com/_/wordpress) and [Redis image page](https://hub.docker.com/_/redis).

## Project Structure

```text
.
├── compose.yaml
├── create-wp-config.sh
├── Dockerfile.phpmyadmin
├── Dockerfile.wordpress
├── docs/
│   ├── ARCHITECTURE.md
│   ├── BACKUP.md
│   ├── CONFIGURATION.md
│   ├── DEPLOY.md
│   ├── MONITORING.md
│   ├── OPTIMIZATION.md
│   ├── SCALING.md
│   └── TROUBLESHOOTING.md
├── scripts/
│   ├── backup.sh
│   ├── restore.sh
│   └── setup-cron.sh
├── generate-ssl-certs.sh
├── install-redis-plugin.sh
├── LICENSE.md
├── nginx/ 
│   ├── default.conf
│   ├── nginx.conf
│   └── ssl/ 
│       ├── cert.pem
│       └── key.pem
├── README.md
├── test-wordpress.sh
└── wordpress-installation.png
```

## Quick Start

```bash
# Copy the sample environment file and rename it to .env
cp dotevn-sample .env

# Start the stack with 3 WordPress instances, 2 Redis instances, and automated backups
docker compose up -d

# Run a manual backup at any time
docker compose exec backup /scripts/backup.sh test
```

## What's Included

- WordPress with load balancing (3 instances)
- MariaDB database
- Redis object caching (2 instances)
- NGINX with reverse proxy and load balancing
- phpMyAdmin for database management
- Automated backup and restore scripts for databases and volumes
- HTTPS support with self-signed certificates (for dev environments)
- Monitoring stack with Prometheus and Grafana
- Health checks for all services to ensure automatic restarts

## Accessing Services

- WordPress: https://localhost/
- phpMyAdmin: http://localhost:8080 (user: wordpress, password: wordpress)
- Grafana: http://localhost:3000 (default user: admin, password: admin)
- Prometheus: http://localhost:9090

> **Default passwords and environment variables can be found in the `dotevn-sample` (or your `.env`) file.**

## Documentation

- [Architecture](docs/ARCHITECTURE.md) - System architecture and component details
- [Deployment](docs/DEPLOY.md) - Detailed deployment instructions and expected results
- [Backup](docs/BACKUP.md) - Backup and restore procedures for data persistence
- [Optimization](docs/OPTIMIZATION.md) - Performance optimizations and image size reduction
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions
- [Scaling](docs/SCALING.md) - Scaling strategies for high traffic
- [Configuration](docs/CONFIGURATION.md) - Configuration details for each service
- [Monitoring](docs/MONITORING.md) - Monitoring stack with Prometheus, Grafana, and exporters for Redis, MariaDB, and NGINX

## License

This project is distributed under the MIT License. See the [LICENSE](LICENSE.md) file for details.