# Hadoop Docker Compose

A complete Hadoop cluster setup using Docker Compose with HDFS and YARN components for distributed data processing and storage.

## Overview

This project provides a fully functional Hadoop cluster running in Docker containers. It includes all essential Hadoop components:

- **HDFS (Hadoop Distributed File System)** for distributed storage
- **YARN (Yet Another Resource Negotiator)** for resource management and job scheduling
- **MapReduce** framework for distributed data processing

The cluster is designed for development, testing, and learning purposes with a single-node setup that can be easily extended for multi-node deployments.

## System Requirements

### Supported Operating Systems
- **macOS**: 10.15+ (Catalina and later)
- **Linux**: Ubuntu 18.04+, CentOS 7+, RHEL 7+, and other modern distributions
- **Windows**: Windows 10/11 with WSL2 or Docker Desktop

### Architecture Support
- **x86_64 (AMD64)**: Full native support
- **ARM64 (Apple Silicon)**: Supported via Docker emulation
  - M1/M2/M3 MacBooks: ✅ Supported (runs via x86_64 emulation)
  - ARM64 Linux servers: ✅ Supported (runs via x86_64 emulation)

### Docker Requirements
- **Docker Engine**: 20.10+ or Docker Desktop 4.0+
- **Docker Compose**: 2.0+ (included with Docker Desktop)
- **Minimum Resources**: 4GB RAM, 2 CPU cores recommended

### Performance Notes
- **x86_64 systems**: Native performance
- **ARM64 systems**: Slightly reduced performance due to emulation
  - Apple Silicon Macs: ~70-80% of native performance
  - ARM64 Linux: ~60-70% of native performance

## Project Structure

```
hadoop/
├── docker-compose.yaml    # Main Docker Compose configuration
├── config                 # Hadoop configuration file
├── hdfs-demo.sh          # Demo script for HDFS operations
├── README.md             # This file
└── docs/                 # Documentation
    ├── ARCHITECTURE.md   # Cluster architecture details
    └── CONFIGURATION.md  # Configuration options
```

## Quick Start

1. **Clone and navigate to the project:**
   ```bash
   cd hadoop
   ```

2. **Start the Hadoop cluster:**
   ```bash
   docker compose up -d
   ```

3. **Wait for services to initialize** (check logs if needed):
   ```bash
   docker compose logs -f
   ```

4. **Run the demo script to verify the setup:**
   ```bash
   docker compose exec resourcemanager bash /opt/hdfs-demo.sh
   ```

5. **Access the web interfaces:**
   - NameNode: http://localhost:9870
   - ResourceManager: http://localhost:8088

## What's Included

### Core Services

- **NameNode (sydney)**: HDFS metadata management
  - Web UI: http://localhost:9870
  - Manages filesystem namespace and metadata

- **DataNode (melbourne)**: HDFS data storage
  - Stores actual data blocks
  - Single node with replication factor 1

- **ResourceManager (brisbane)**: YARN resource management
  - Web UI: http://localhost:8088
  - Manages cluster resources and job scheduling

- **NodeManager (perth)**: YARN node management
  - Manages resources on individual nodes
  - Handles container lifecycle

### Configuration

- **Centralized config file**: All Hadoop settings in `./config`
- **Custom network**: Isolated `hadoop` network with hostname aliases
- **Demo script**: `hdfs-demo.sh` for basic HDFS operations

### Features

- ✅ HDFS distributed file system
- ✅ YARN resource management
- ✅ MapReduce framework
- ✅ Capacity scheduler
- ✅ Web-based monitoring interfaces
- ✅ Easy configuration management
- ✅ Development-ready setup

## Accessing Services

### Web Interfaces

| Service | URL | Description |
|---------|-----|-------------|
| NameNode | http://localhost:9870 | HDFS filesystem browser and status |
| ResourceManager | http://localhost:8088 | YARN cluster and job monitoring |

### Command Line Access

**Access HDFS commands:**
```bash
docker compose exec resourcemanager hdfs dfs -ls /
```

**Access YARN commands:**
```bash
docker compose exec resourcemanager yarn application -list
```

**Run the demo script:**
```bash
docker compose exec resourcemanager bash /opt/hdfs-demo.sh
```

**Check cluster status:**
```bash
docker compose exec resourcemanager hdfs dfsadmin -report
docker compose exec resourcemanager yarn node -list
```

### File Operations

**Upload files to HDFS:**
```bash
docker compose exec resourcemanager hdfs dfs -put localfile.txt /user/root/
```

**List HDFS contents:**
```bash
docker compose exec resourcemanager hdfs dfs -ls /user/root
```

**Download files from HDFS:**
```bash
docker compose exec resourcemanager hdfs dfs -get /user/root/file.txt /tmp/
```

## Documentation

### [Architecture Documentation](docs/ARCHITECTURE.md)

Detailed information about:
- Cluster component architecture
- Network topology
- Data flow patterns
- Scalability considerations

### [Configuration Documentation](docs/CONFIGURATION.md)

Comprehensive guide covering:
- Configuration file format
- Available settings
- Customization options
- Environment variables
- Validation procedures

## Troubleshooting

### Common Issues

**Services not starting:**
```bash
docker compose logs [service-name]
```

**HDFS not accessible:**
```bash
docker compose exec resourcemanager hdfs dfsadmin -safemode leave
```

**YARN applications failing:**
```bash
docker compose exec resourcemanager yarn application -list
```

### Architecture-Specific Issues

**ARM64 (Apple Silicon) Performance Issues:**
- **Slow startup**: Normal due to emulation overhead
- **Reduced performance**: Expected on ARM64 systems
- **Memory pressure**: Consider increasing Docker memory limits to 6-8GB

**Platform Compatibility Warnings:**
- **"platform does not match" warnings**: Normal on ARM64, Docker handles emulation automatically
- **HADOOP_HOME warnings**: Resolved by setting environment variables in docker-compose.yaml

**Performance Optimization for ARM64:**
```bash
# Increase Docker memory allocation (Docker Desktop)
# Settings > Resources > Memory: 8GB recommended

# Monitor resource usage
docker stats
```

### Logs and Monitoring

**View all logs:**
```bash
docker compose logs -f
```

**View specific service logs:**
```bash
docker compose logs -f namenode
docker compose logs -f resourcemanager
```

## Development

### Extending the Setup

1. **Add more DataNodes** by duplicating the datanode service in `docker-compose.yaml`
2. **Add more NodeManagers** by duplicating the nodemanager service
3. **Modify configuration** by editing the `config` file
4. **Add custom scripts** by mounting volumes to containers

### Custom Configuration

Edit the `config` file to modify Hadoop settings:
```bash
# Example: Change HDFS replication factor
HDFS-SITE.XML_dfs.replication=3
```

## License

This project is part of the [awesome-compose](https://github.com/docker/awesome-compose) collection.

## References

- [Apache Hadoop Documentation](https://hadoop.apache.org/docs/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Apache Hadoop Docker Image](https://hub.docker.com/r/apache/hadoop)
