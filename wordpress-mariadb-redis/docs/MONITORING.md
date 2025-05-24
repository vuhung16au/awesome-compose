# Monitoring and Observability

This project includes a robust monitoring stack using Prometheus and Grafana, along with exporters for Redis, MariaDB, and NGINX. This setup provides real-time metrics, dashboards, and observability for all major services in the WordPress-MariaDB-Redis environment.

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

---

For more details, see the configuration files in the `prometheus/` and `nginx/` directories.
