#!/bin/bash
# Schedule automated backups within the Docker container

set -e

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if we're supposed to run in test mode
if [ "$1" = "test" ]; then
  echo -e "${YELLOW}Running backup in test mode...${NC}"
  exec /scripts/backup.sh
  exit 0
fi

# Default cron schedule (daily at 2:00 AM)
CRON_SCHEDULE=${BACKUP_SCHEDULE:-"0 2 * * *"}
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-7}

echo -e "${BLUE}====== Configuring Automated Backups ======${NC}\n"
echo -e "${GREEN}Backup Schedule: $CRON_SCHEDULE${NC}"
echo -e "${GREEN}Retention Period: $RETENTION_DAYS days${NC}"

# Update retention period in backup script
sed -i "s/RETENTION_DAYS=7/RETENTION_DAYS=$RETENTION_DAYS/g" /scripts/backup.sh

# Create crontab file
echo "$CRON_SCHEDULE /scripts/backup.sh >> /var/log/backup.log 2>&1" > /etc/cron.d/backup-cron
chmod 0644 /etc/cron.d/backup-cron

# Apply cron file
crontab /etc/cron.d/backup-cron

# Start cron
echo -e "${GREEN}Starting cron service...${NC}"
crond -f -L /var/log/cron.log
