# Hadoop Configuration

This document describes the configuration options available for the Hadoop cluster.

## Configuration File

The main configuration is stored in the `config` file at the root of the project. This file uses a custom format where each line represents a Hadoop configuration property.

### Configuration Format

```
CONFIG_FILE.PROPERTY_NAME=value
```

For example:
```
CORE-SITE.XML_fs.defaultFS=hdfs://sydney
```

## Platform-Specific Configuration

### Architecture Considerations

#### x86_64 (AMD64) Systems
- **Default Configuration**: Optimized for native performance
- **Memory Allocation**: Standard Docker memory limits apply
- **CPU Allocation**: Full CPU access available

#### ARM64 Systems (Apple Silicon, ARM64 Linux)
- **Emulation Overhead**: Consider increased memory allocation
- **Performance Tuning**: May require adjusted resource limits
- **Memory Recommendations**: 
  - Minimum: 6GB RAM (vs 4GB for x86_64)
  - Recommended: 8GB+ RAM for better performance

### Environment Variables

The following environment variables are automatically set for all services:

```yaml
environment:
  HADOOP_HOME: "/opt/hadoop"
```

This ensures proper Hadoop environment setup across all architectures.

### Docker Compose Platform Handling

The Docker Compose configuration automatically handles platform differences:

- **x86_64**: Direct container execution
- **ARM64**: Automatic emulation via Docker's built-in x86_64 emulation
- **No manual platform specification**: Docker automatically selects the appropriate execution method

## Core Configuration Sections

### Core Site Configuration
Controls fundamental Hadoop settings:

```bash
CORE-SITE.XML_fs.default.name=hdfs://sydney
CORE-SITE.XML_fs.defaultFS=hdfs://sydney
```

**Key Properties:**
- `fs.defaultFS`: Default filesystem URI
- `fs.default.name`: Legacy property for default filesystem

### HDFS Site Configuration
Controls HDFS-specific settings:

```bash
HDFS-SITE.XML_dfs.namenode.rpc-address=sydney:8020
HDFS-SITE.XML_dfs.replication=1
```

**Key Properties:**
- `dfs.namenode.rpc-address`: NameNode RPC address
- `dfs.replication`: Number of replicas for each block

### MapReduce Site Configuration
Controls MapReduce framework settings:

```bash
MAPRED-SITE.XML_mapreduce.framework.name=yarn
MAPRED-SITE.XML_yarn.app.mapreduce.am.env=HADOOP_MAPRED_HOME=$HADOOP_HOME
MAPRED-SITE.XML_mapreduce.map.env=HADOOP_MAPRED_HOME=$HADOOP_HOME
MAPRED-SITE.XML_mapreduce.reduce.env=HADOOP_MAPRED_HOME=$HADOOP_HOME
```

**Key Properties:**
- `mapreduce.framework.name`: Execution framework (yarn)
- `yarn.app.mapreduce.am.env`: Application master environment
- `mapreduce.map.env`: Map task environment
- `mapreduce.reduce.env`: Reduce task environment

### YARN Site Configuration
Controls YARN resource management:

```bash
YARN-SITE.XML_yarn.resourcemanager.hostname=brisbane
YARN-SITE.XML_yarn.nodemanager.pmem-check-enabled=false
YARN-SITE.XML_yarn.nodemanager.delete.debug-delay-sec=600
YARN-SITE.XML_yarn.nodemanager.vmem-check-enabled=false
YARN-SITE.XML_yarn.nodemanager.aux-services=mapreduce_shuffle
```

**Key Properties:**
- `yarn.resourcemanager.hostname`: ResourceManager hostname
- `yarn.nodemanager.pmem-check-enabled`: Physical memory check
- `yarn.nodemanager.vmem-check-enabled`: Virtual memory check
- `yarn.nodemanager.aux-services`: Auxiliary services

### Capacity Scheduler Configuration
Controls YARN job scheduling:

```bash
CAPACITY-SCHEDULER.XML_yarn.scheduler.capacity.maximum-applications=10000
CAPACITY-SCHEDULER.XML_yarn.scheduler.capacity.maximum-am-resource-percent=0.1
CAPACITY-SCHEDULER.XML_yarn.scheduler.capacity.resource-calculator=org.apache.hadoop.yarn.util.resource.DefaultResourceCalculator
CAPACITY-SCHEDULER.XML_yarn.scheduler.capacity.root.queues=default
CAPACITY-SCHEDULER.XML_yarn.scheduler.capacity.root.default.capacity=100
```

**Key Properties:**
- `yarn.scheduler.capacity.maximum-applications`: Max concurrent applications
- `yarn.scheduler.capacity.maximum-am-resource-percent`: Max AM resource percentage
- `yarn.scheduler.capacity.root.queues`: Available queues
- `yarn.scheduler.capacity.root.default.capacity`: Default queue capacity

## Environment Variables

The configuration is applied through environment variables in the Docker Compose file:

```yaml
env_file:
  - ./config
```

## Customization Options

### Memory Configuration
To adjust memory limits, modify the YARN configuration:

```bash
YARN-SITE.XML_yarn.nodemanager.resource.memory-mb=4096
YARN-SITE.XML_yarn.scheduler.maximum-allocation-mb=4096
YARN-SITE.XML_yarn.scheduler.minimum-allocation-mb=256
```

### HDFS Configuration
To change HDFS settings:

```bash
HDFS-SITE.XML_dfs.blocksize=134217728
HDFS-SITE.XML_dfs.namenode.handler.count=20
```

### Security Configuration
For production environments, add security settings:

```bash
CORE-SITE.XML_hadoop.security.authentication=kerberos
CORE-SITE.XML_hadoop.security.authorization=true
```

## Docker Compose Configuration

### Port Mappings
- NameNode Web UI: `9870:9870`
- ResourceManager Web UI: `8088:8088`

### Volume Mounts
- Demo script: `./hdfs-demo.sh:/opt/hdfs-demo.sh`

### Network Configuration
All services use the `hadoop` network with hostname aliases for service discovery.

## Validation

After making configuration changes:

1. Restart the cluster:
   ```bash
   docker compose down
   docker compose up -d
   ```

2. Verify configuration:
   ```bash
   docker compose exec resourcemanager hdfs dfsadmin -report
   docker compose exec resourcemanager yarn node -list
   ```

3. Check web interfaces:
   - NameNode: http://localhost:9870
   - ResourceManager: http://localhost:8088
