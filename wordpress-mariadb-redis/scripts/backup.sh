#!/bin/bash
# Automated Backup Script for WordPress, MariaDB, and Redis setup

# Set color codes for better visibility
GREEN='\033[0;32m'
YELLOW=# 4. Backup Grafana data
echo -e# 6. Create backup summary
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
echo -e "\n${BLUE}====== Backup Summary ======${NC}"
echo -e "${GREEN}Date: $DATE${NC}"
echo -e "${GREEN}Total backup size: $TOTAL_SIZE${NC}"
echo -e "${GREEN}Backup location: $BACKUP_DIR${NC}"
echo -e "${GREEN}Retention policy: $RETENTION_DAYS days${NC}"
echo -e "${GREEN}Execution mode: $(if [ "$IS_CONTAINER" = true ]; then echo "Container"; else echo "Host"; fi)${NC}"
echo -e "${BLUE}=============================${NC}\n"LLOW}Backing up Grafana data...${NC}"
GRAFANA_BACKUP="$BACKUP_DIR/volumes/grafana_data_${DATE}.tar"
if [ "$IS_CONTAINER" = true ]; then
  # When running inside the backup container
  tar cf "$GRAFANA_BACKUP" -C /grafana_data .
else
  # When running on the host
  COMPOSE_PROJECT_NAME=$(basename "$(pwd)" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
  docker run --rm \
    --volume ${COMPOSE_PROJECT_NAME}_grafana_data:/source:ro \
    --volume $(pwd)/$BACKUP_DIR/volumes:/backup \
    alpine tar cf "/backup/grafana_data_${DATE}.tar" -C /source .
fi

if [ $? -eq 0 ]; then
  echo -e "${GREEN}Grafana data backup successful: $GRAFANA_BACKUP${NC}"
  # Compress the volume backup
  gzip "$GRAFANA_BACKUP"
  echo -e "${GREEN}Grafana data backup compressed: $GRAFANA_BACKUP.gz${NC}"
else
  echo -e "${RED}Grafana data backup failed!${NC}"
fi

# 5. Clean up old backups
echo -e "\n${YELLOW}Cleaning up old backups (older than $RETENTION_DAYS days)...${NC}"
find "$BACKUP_DIR" -type f -name "*.gz" -mtime +$RETENTION_DAYS -delete
echo -e "${GREEN}Old backups cleaned up.${NC}"3[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
# Check if we're running inside Docker (container provided by Dockerfile.backup)
if [ -d "/backups" ] && [ -d "/var/lib/mysql" ]; then
  BACKUP_DIR="/backups"
  IS_CONTAINER=true
else
  BACKUP_DIR="./backups"
  IS_CONTAINER=false
fi

DATE=$(date +%Y-%m-%d_%H-%M-%S)
RETENTION_DAYS=7  # Number of days to keep backups

echo -e "${BLUE}====== Starting Backup Process: $DATE ======${NC}\n"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR/databases"
mkdir -p "$BACKUP_DIR/volumes"

# 1. Backup MariaDB database
echo -e "${YELLOW}Backing up MariaDB database...${NC}"
if [ "$IS_CONTAINER" = true ]; then
  # When running inside the backup container
  mysqldump --host=mariadb --all-databases -uroot -p"$MYSQL_ROOT_PASSWORD" > \
    "$BACKUP_DIR/databases/mariadb_all_${DATE}.sql"
else
  # When running on the host
  COMPOSE_PROJECT_NAME=$(basename "$(pwd)" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
  docker exec ${COMPOSE_PROJECT_NAME}-mariadb-1 \
    sh -c 'exec mysqldump --all-databases -uroot -p"$MYSQL_ROOT_PASSWORD"' > \
    "$BACKUP_DIR/databases/mariadb_all_${DATE}.sql"
fi

if [ $? -eq 0 ]; then
  echo -e "${GREEN}Database backup successful: $BACKUP_DIR/databases/mariadb_all_${DATE}.sql${NC}"
  # Compress the database backup
  gzip "$BACKUP_DIR/databases/mariadb_all_${DATE}.sql"
  echo -e "${GREEN}Database backup compressed: $BACKUP_DIR/databases/mariadb_all_${DATE}.sql.gz${NC}"
else
  echo -e "${RED}Database backup failed!${NC}"
fi

# 2. Backup WordPress uploads volume
echo -e "\n${YELLOW}Backing up WordPress uploads volume...${NC}"
UPLOADS_BACKUP="$BACKUP_DIR/volumes/wordpress_uploads_${DATE}.tar"
if [ "$IS_CONTAINER" = true ]; then
  # When running inside the backup container
  tar cf "$UPLOADS_BACKUP" -C /var/www/html/wp-content/uploads .
else
  # When running on the host
  COMPOSE_PROJECT_NAME=$(basename "$(pwd)" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
  docker run --rm \
    --volume ${COMPOSE_PROJECT_NAME}_wordpress_uploads:/source:ro \
    --volume $(pwd)/$BACKUP_DIR/volumes:/backup \
    alpine tar cf "/backup/wordpress_uploads_${DATE}.tar" -C /source .
fi

if [ $? -eq 0 ]; then
  echo -e "${GREEN}WordPress uploads backup successful: $UPLOADS_BACKUP${NC}"
  # Compress the volume backup
  gzip "$UPLOADS_BACKUP"
  echo -e "${GREEN}WordPress uploads backup compressed: $UPLOADS_BACKUP.gz${NC}"
else
  echo -e "${RED}WordPress uploads backup failed!${NC}"
fi

# 3. Backup Redis data volumes
echo -e "\n${YELLOW}Backing up Redis data volumes...${NC}"

# Backup Redis-1 data
echo -e "${YELLOW}Backing up Redis-1 data...${NC}"
REDIS1_BACKUP="$BACKUP_DIR/volumes/redis1_data_${DATE}.tar"
if [ "$IS_CONTAINER" = true ]; then
  # When running inside the backup container
  tar cf "$REDIS1_BACKUP" -C /redis1_data .
else
  # When running on the host
  COMPOSE_PROJECT_NAME=$(basename "$(pwd)" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
  docker run --rm \
    --volume ${COMPOSE_PROJECT_NAME}_redis_data_1:/source:ro \
    --volume $(pwd)/$BACKUP_DIR/volumes:/backup \
    alpine tar cf "/backup/redis1_data_${DATE}.tar" -C /source .
fi

if [ $? -eq 0 ]; then
  echo -e "${GREEN}Redis-1 data backup successful: $REDIS1_BACKUP${NC}"
  # Compress the volume backup
  gzip "$REDIS1_BACKUP"
  echo -e "${GREEN}Redis-1 data backup compressed: $REDIS1_BACKUP.gz${NC}"
else
  echo -e "${RED}Redis-1 data backup failed!${NC}"
fi

# Backup Redis-2 data
echo -e "${YELLOW}Backing up Redis-2 data...${NC}"
REDIS2_BACKUP="$BACKUP_DIR/volumes/redis2_data_${DATE}.tar"
if [ "$IS_CONTAINER" = true ]; then
  # When running inside the backup container
  tar cf "$REDIS2_BACKUP" -C /redis2_data .
else
  # When running on the host
  COMPOSE_PROJECT_NAME=$(basename "$(pwd)" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
  docker run --rm \
    --volume ${COMPOSE_PROJECT_NAME}_redis_data_2:/source:ro \
    --volume $(pwd)/$BACKUP_DIR/volumes:/backup \
    alpine tar cf "/backup/redis2_data_${DATE}.tar" -C /source .
fi

if [ $? -eq 0 ]; then
  echo -e "${GREEN}Redis-2 data backup successful: $REDIS2_BACKUP${NC}"
  # Compress the volume backup
  gzip "$REDIS2_BACKUP"
  echo -e "${GREEN}Redis-2 data backup compressed: $REDIS2_BACKUP.gz${NC}"
else
  echo -e "${RED}Redis-2 data backup failed!${NC}"
fi

# 4. Backup Grafana data
echo -e "\n${YELLOW}Backing up Grafana data...${NC}"
GRAFANA_BACKUP="$BACKUP_DIR/volumes/grafana_data_${DATE}.tar"
docker run --rm \
  --volume ${COMPOSE_PROJECT_NAME}_grafana_data:/source:ro \
  --volume $(pwd)/$BACKUP_DIR/volumes:/backup \
  alpine tar cf "/backup/grafana_data_${DATE}.tar" -C /source .

if [ $? -eq 0 ]; then
  echo -e "${GREEN}Grafana data backup successful: $GRAFANA_BACKUP${NC}"
  # Compress the volume backup
  gzip "$GRAFANA_BACKUP"
  echo -e "${GREEN}Grafana data backup compressed: $GRAFANA_BACKUP.gz${NC}"
else
  echo -e "${RED}Grafana data backup failed!${NC}"
fi

# 5. Clean up old backups
echo -e "\n${YELLOW}Cleaning up old backups (older than $RETENTION_DAYS days)...${NC}"
find "$BACKUP_DIR" -type f -name "*.gz" -mtime +$RETENTION_DAYS -delete
echo -e "${GREEN}Old backups cleaned up.${NC}"

# 6. Create backup summary
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
echo -e "\n${BLUE}====== Backup Summary ======${NC}"
echo -e "${GREEN}Date: $DATE${NC}"
echo -e "${GREEN}Total backup size: $TOTAL_SIZE${NC}"
echo -e "${GREEN}Backup location: $BACKUP_DIR${NC}"
echo -e "${GREEN}Retention policy: $RETENTION_DAYS days${NC}"
echo -e "${BLUE}=============================${NC}\n"

# 7. Optional: Upload to remote storage (S3, Google Cloud Storage, etc.)
# Uncomment and configure as needed
# echo -e "${YELLOW}Uploading backups to remote storage...${NC}"
# aws s3 sync "$BACKUP_DIR" "s3://your-bucket/backups/"
# echo -e "${GREEN}Upload complete.${NC}"

echo -e "${BLUE}====== Backup Process Completed ======${NC}"
