# Monitoring and Observability

This project includes a robust monitoring stack using Prometheus and Grafana, along with exporters for Redis, MariaDB, and NGINX. This setup provides real-time metrics, dashboards, and observability for all major services in the WordPress-MariaDB-Redis environment. Additionally, Docker healthchecks have been implemented for all services to ensure automatic recovery from failures.

## Components

- **Prometheus**: Collects and stores metrics from exporters and services.
- **Grafana**: Visualizes metrics with pre-built and custom dashboards.
- **Exporters**:
  - **Redis Exporter**: Exposes Redis metrics for Prometheus.
  - **MariaDB Exporter**: Exposes MariaDB metrics for Prometheus.
  - **NGINX Exporter**: Exposes NGINX metrics for Prometheus.

## How It Works

- Each service (Redis, MariaDB, NGINX) runs an exporter container.
- Prometheus scrapes metrics from these exporters at regular intervals (see `prometheus/prometheus.yml`).
- Grafana connects to Prometheus as a data source and provides dashboards for visualization.
- The NGINX config exposes a `/stub_status` endpoint for the exporter to collect metrics.

## Accessing Monitoring Tools

- **Prometheus UI**: [http://localhost:9090](http://localhost:9090)
- **Grafana UI**: [http://localhost:3000](http://localhost:3000) (default user: `admin`, password: `admin`)

## Example Dashboards

- Import official dashboards from Grafana.com for Redis (ID: 763), MariaDB (ID: 7362), and NGINX (ID: 2949).
- Create custom dashboards for application-specific metrics as needed.

## How to Extend

- Add more exporters for other services as needed.
- Customize Prometheus scrape intervals and targets in `prometheus/prometheus.yml`.
- Build your own Grafana dashboards for deeper insights.

## Docker Healthchecks

All services in this stack include Docker healthchecks that:

- Monitor the health of each container
- Automatically restart containers when they become unhealthy
- Provide visibility into container health via `docker ps` or Docker Desktop

| Service | Health Check Method | Check Interval | Retries | Start Period |
|---------|---------------------|----------------|---------|--------------|
| NGINX | HTTP request to port 80 | 30s | 3 | 15s |
| WordPress | HTTP request to web server | 1m | 3 | 30s |
| MariaDB | `mysqladmin ping` command | 30s | 5 | 30s |
| Redis | `redis-cli ping` command | 30s | 3 | 15s |
| phpMyAdmin | HTTP request to port 80 | 30s | 3 | 15s |
| Prometheus | HTTP health endpoint | 30s | 3 | 15s |
| Grafana | API health endpoint | 30s | 3 | 15s |
| Exporters | HTTP metrics endpoint | 30s | 3 | 15s |

### Viewing Health Status

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Health}}"
```

This will show all containers with their health status (healthy, unhealthy, or starting).

---

For more details, see the configuration files in the `prometheus/` and `nginx/` directories.
