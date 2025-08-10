# Hadoop Architecture

This document describes the architecture of the Hadoop cluster deployed using Docker Compose.

## Overview

The Hadoop cluster consists of four main components distributed across separate containers:

- **NameNode** (sydney): HDFS metadata management
- **DataNode** (melbourne): HDFS data storage
- **ResourceManager** (brisbane): YARN resource management
- **NodeManager** (perth): YARN node management

## Platform Architecture

### Container Architecture
- **Base Image**: `apache/hadoop:3` (x86_64/AMD64)
- **Container Runtime**: Docker with Linux containers
- **Network**: Custom Docker network with hostname-based service discovery

### Cross-Platform Compatibility

#### x86_64 (AMD64) Systems
- **Native Support**: ✅ Full native performance
- **Deployment**: Direct container execution
- **Performance**: Optimal performance with no overhead

#### ARM64 Systems (Apple Silicon, ARM64 Linux)
- **Emulation Support**: ✅ Runs via x86_64 emulation
- **Deployment**: Docker automatically handles architecture translation
- **Performance**: Reduced performance due to emulation overhead
  - Apple Silicon (M1/M2/M3): ~70-80% of native performance
  - ARM64 Linux: ~60-70% of native performance

### Operating System Support

#### macOS
- **Docker Desktop**: Recommended for M1/M2/M3 Macs
- **Docker Engine**: Available via Homebrew or Docker Desktop
- **Performance**: Good with Docker Desktop's optimized emulation

#### Linux
- **x86_64**: Native performance
- **ARM64**: Emulated performance
- **Docker Engine**: Native installation

#### Windows
- **WSL2**: Recommended for development
- **Docker Desktop**: Full support
- **Performance**: Varies based on WSL2 configuration

## Component Details

### NameNode (sydney)
- **Purpose**: Manages the HDFS filesystem namespace and metadata
- **Port**: 9870 (Web UI)
- **Hostname**: sydney
- **Command**: `hdfs namenode`
- **Storage**: `/tmp/hadoop-root/dfs/name`

### DataNode (melbourne)
- **Purpose**: Stores actual HDFS data blocks
- **Hostname**: melbourne
- **Command**: `hdfs datanode`
- **Replication**: 1 (single node setup)

### ResourceManager (brisbane)
- **Purpose**: Manages YARN cluster resources and job scheduling
- **Port**: 8088 (Web UI)
- **Hostname**: brisbane
- **Command**: `yarn resourcemanager`
- **Features**: 
  - Capacity Scheduler configuration
  - Job submission and monitoring
  - Resource allocation

### NodeManager (perth)
- **Purpose**: Manages resources on individual nodes
- **Hostname**: perth
- **Command**: `yarn nodemanager`
- **Features**:
  - Container lifecycle management
  - Resource monitoring
  - MapReduce shuffle service

## Network Architecture

All components communicate through a custom Docker network named `hadoop` with the following aliases:
- `sydney` → NameNode
- `melbourne` → DataNode  
- `brisbane` → ResourceManager
- `perth` → NodeManager

## Configuration

The cluster uses a centralized configuration file (`config`) that defines:
- HDFS settings (replication, namenode address)
- YARN settings (resource manager hostname, memory checks)
- MapReduce framework configuration
- Capacity scheduler parameters

## Data Flow

1. **HDFS Operations**: Client → NameNode (metadata) → DataNode (data)
2. **YARN Jobs**: Client → ResourceManager → NodeManager → Containers
3. **MapReduce**: ResourceManager schedules → NodeManager executes → DataNode stores results

## Scalability Considerations

This is a single-node development setup with:
- Single DataNode (replication factor = 1)
- Single NodeManager
- No high availability features

For production use, consider:
- Multiple DataNodes for redundancy
- Multiple NodeManagers for parallel processing
- NameNode high availability
- ResourceManager high availability
