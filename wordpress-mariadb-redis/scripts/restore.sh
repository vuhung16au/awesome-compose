#!/bin/bash
# Automated Restore Script for WordPress, MariaDB, and Redis setup

# Set color codes for better visibility
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're running inside Docker (container provided by Dockerfile.backup)
if [ -d "/backups" ] && [ -d "/var/lib/mysql" ]; then
  BACKUP_DIR="/backups"
  IS_CONTAINER=true
else
  BACKUP_DIR="./backups"
  IS_CONTAINER=false
  COMPOSE_PROJECT_NAME=$(basename "$(pwd)" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
fi

# Display usage information
function show_usage {
  echo -e "${YELLOW}Usage: $0 [OPTIONS]${NC}"
  echo -e "  --db BACKUP_FILE     Restore database from specified backup file"
  echo -e "  --uploads BACKUP_FILE Restore WordPress uploads from specified backup file"
  echo -e "  --redis1 BACKUP_FILE Restore Redis-1 data from specified backup file"
  echo -e "  --redis2 BACKUP_FILE Restore Redis-2 data from specified backup file"
  echo -e "  --grafana BACKUP_FILE Restore Grafana data from specified backup file"
  echo -e "  --list               List available backups"
  echo -e "  --help               Display this help message"
  echo
  echo -e "${YELLOW}Examples:${NC}"
  echo -e "  $0 --list"
  echo -e "  $0 --db backups/databases/mariadb_all_2023-05-24_15-30-00.sql.gz"
  echo -e "  $0 --uploads backups/volumes/wordpress_uploads_2023-05-24_15-30-00.tar.gz"
}

# List available backups
function list_backups {
  echo -e "${BLUE}====== Available Backups ======${NC}\n"
  
  echo -e "${YELLOW}Database Backups:${NC}"
  find ./backups/databases -type f -name "*.sql.gz" | sort
  
  echo -e "\n${YELLOW}WordPress Uploads Backups:${NC}"
  find ./backups/volumes -type f -name "wordpress_uploads_*.tar.gz" | sort
  
  echo -e "\n${YELLOW}Redis-1 Data Backups:${NC}"
  find ./backups/volumes -type f -name "redis1_data_*.tar.gz" | sort
  
  echo -e "\n${YELLOW}Redis-2 Data Backups:${NC}"
  find ./backups/volumes -type f -name "redis2_data_*.tar.gz" | sort
  
  echo -e "\n${YELLOW}Grafana Data Backups:${NC}"
  find ./backups/volumes -type f -name "grafana_data_*.tar.gz" | sort
  
  echo -e "\n${BLUE}=============================${NC}\n"
}

# Restore database
function restore_database {
  BACKUP_FILE=$1
  
  if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}Error: Database backup file not found: $BACKUP_FILE${NC}"
    exit 1
  fi
  
  echo -e "${YELLOW}Restoring MariaDB database from $BACKUP_FILE...${NC}"
  
  # Extract the compressed backup
  gunzip -c "$BACKUP_FILE" > /tmp/db_restore.sql
  
  # Import the SQL dump
  cat /tmp/db_restore.sql | docker exec -i ${COMPOSE_PROJECT_NAME}-mariadb-1 \
    sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD"'
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Database restore completed successfully.${NC}"
    rm /tmp/db_restore.sql
  else
    echo -e "${RED}Database restore failed!${NC}"
    exit 1
  fi
}

# Restore WordPress uploads
function restore_uploads {
  BACKUP_FILE=$1
  
  if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}Error: WordPress uploads backup file not found: $BACKUP_FILE${NC}"
    exit 1
  fi
  
  echo -e "${YELLOW}Restoring WordPress uploads from $BACKUP_FILE...${NC}"
  
  # Create a temporary directory
  mkdir -p /tmp/wp_uploads_restore
  
  # Extract the compressed backup
  gunzip -c "$BACKUP_FILE" > /tmp/wp_uploads_restore/uploads.tar
  
  # Restore the volume
  docker run --rm \
    --volume ${COMPOSE_PROJECT_NAME}_wordpress_uploads:/destination \
    --volume /tmp/wp_uploads_restore:/backup \
    alpine sh -c "rm -rf /destination/* && tar xf /backup/uploads.tar -C /destination"
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}WordPress uploads restore completed successfully.${NC}"
    rm -rf /tmp/wp_uploads_restore
  else
    echo -e "${RED}WordPress uploads restore failed!${NC}"
    exit 1
  fi
}

# Restore Redis-1 data
function restore_redis1 {
  BACKUP_FILE=$1
  
  if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}Error: Redis-1 backup file not found: $BACKUP_FILE${NC}"
    exit 1
  fi
  
  echo -e "${YELLOW}Stopping Redis-1 service...${NC}"
  docker stop ${COMPOSE_PROJECT_NAME}-redis-1-1
  
  echo -e "${YELLOW}Restoring Redis-1 data from $BACKUP_FILE...${NC}"
  
  # Create a temporary directory
  mkdir -p /tmp/redis1_restore
  
  # Extract the compressed backup
  gunzip -c "$BACKUP_FILE" > /tmp/redis1_restore/redis1.tar
  
  # Restore the volume
  docker run --rm \
    --volume ${COMPOSE_PROJECT_NAME}_redis_data_1:/destination \
    --volume /tmp/redis1_restore:/backup \
    alpine sh -c "rm -rf /destination/* && tar xf /backup/redis1.tar -C /destination"
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Redis-1 data restore completed successfully.${NC}"
    rm -rf /tmp/redis1_restore
    
    echo -e "${YELLOW}Starting Redis-1 service...${NC}"
    docker start ${COMPOSE_PROJECT_NAME}-redis-1-1
    echo -e "${GREEN}Redis-1 service started.${NC}"
  else
    echo -e "${RED}Redis-1 data restore failed!${NC}"
    docker start ${COMPOSE_PROJECT_NAME}-redis-1-1
    exit 1
  fi
}

# Restore Redis-2 data
function restore_redis2 {
  BACKUP_FILE=$1
  
  if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}Error: Redis-2 backup file not found: $BACKUP_FILE${NC}"
    exit 1
  fi
  
  echo -e "${YELLOW}Stopping Redis-2 service...${NC}"
  docker stop ${COMPOSE_PROJECT_NAME}-redis-2-1
  
  echo -e "${YELLOW}Restoring Redis-2 data from $BACKUP_FILE...${NC}"
  
  # Create a temporary directory
  mkdir -p /tmp/redis2_restore
  
  # Extract the compressed backup
  gunzip -c "$BACKUP_FILE" > /tmp/redis2_restore/redis2.tar
  
  # Restore the volume
  docker run --rm \
    --volume ${COMPOSE_PROJECT_NAME}_redis_data_2:/destination \
    --volume /tmp/redis2_restore:/backup \
    alpine sh -c "rm -rf /destination/* && tar xf /backup/redis2.tar -C /destination"
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Redis-2 data restore completed successfully.${NC}"
    rm -rf /tmp/redis2_restore
    
    echo -e "${YELLOW}Starting Redis-2 service...${NC}"
    docker start ${COMPOSE_PROJECT_NAME}-redis-2-1
    echo -e "${GREEN}Redis-2 service started.${NC}"
  else
    echo -e "${RED}Redis-2 data restore failed!${NC}"
    docker start ${COMPOSE_PROJECT_NAME}-redis-2-1
    exit 1
  fi
}

# Restore Grafana data
function restore_grafana {
  BACKUP_FILE=$1
  
  if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}Error: Grafana backup file not found: $BACKUP_FILE${NC}"
    exit 1
  fi
  
  echo -e "${YELLOW}Stopping Grafana service...${NC}"
  docker stop ${COMPOSE_PROJECT_NAME}-grafana-1
  
  echo -e "${YELLOW}Restoring Grafana data from $BACKUP_FILE...${NC}"
  
  # Create a temporary directory
  mkdir -p /tmp/grafana_restore
  
  # Extract the compressed backup
  gunzip -c "$BACKUP_FILE" > /tmp/grafana_restore/grafana.tar
  
  # Restore the volume
  docker run --rm \
    --volume ${COMPOSE_PROJECT_NAME}_grafana_data:/destination \
    --volume /tmp/grafana_restore:/backup \
    alpine sh -c "rm -rf /destination/* && tar xf /backup/grafana.tar -C /destination"
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Grafana data restore completed successfully.${NC}"
    rm -rf /tmp/grafana_restore
    
    echo -e "${YELLOW}Starting Grafana service...${NC}"
    docker start ${COMPOSE_PROJECT_NAME}-grafana-1
    echo -e "${GREEN}Grafana service started.${NC}"
  else
    echo -e "${RED}Grafana data restore failed!${NC}"
    docker start ${COMPOSE_PROJECT_NAME}-grafana-1
    exit 1
  fi
}

# Check if no arguments were provided
if [ $# -eq 0 ]; then
  show_usage
  exit 1
fi

# Parse command line arguments
while [ $# -gt 0 ]; do
  case "$1" in
    --db)
      restore_database "$2"
      shift 2
      ;;
    --uploads)
      restore_uploads "$2"
      shift 2
      ;;
    --redis1)
      restore_redis1 "$2"
      shift 2
      ;;
    --redis2)
      restore_redis2 "$2"
      shift 2
      ;;
    --grafana)
      restore_grafana "$2"
      shift 2
      ;;
    --list)
      list_backups
      shift
      ;;
    --help)
      show_usage
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      show_usage
      exit 1
      ;;
  esac
done

echo -e "${BLUE}====== Restore Process Completed ======${NC}"
