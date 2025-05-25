#!/bin/bash
# Setup automatic backup cron job

# Set color codes for better visibility
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}====== Setting Up Automatic Backups ======${NC}\n"

# Check if script is run with sudo
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run with sudo for crontab setup${NC}"
  exit 1
fi

# Make backup script executable
chmod +x ./scripts/backup.sh
chmod +x ./scripts/restore.sh

# Get absolute path to backup script
BACKUP_SCRIPT_PATH=$(realpath ./scripts/backup.sh)
PROJECT_DIR=$(pwd)

# Ask for backup schedule
echo -e "${YELLOW}How often should backups run?${NC}"
echo -e "1) Daily (recommended)"
echo -e "2) Weekly"
echo -e "3) Monthly"
echo -e "4) Custom schedule"

read -p "Select option (1-4): " schedule_option

case $schedule_option in
  1)
    read -p "What time should daily backups run? (HH:MM, 24hr format) [02:00]: " backup_time
    backup_time=${backup_time:-02:00}
    hour=${backup_time%:*}
    minute=${backup_time#*:}
    cron_schedule="$minute $hour * * *"
    schedule_desc="daily at $backup_time"
    ;;
  2)
    read -p "Which day of the week? (0-6, where 0=Sunday) [0]: " backup_day
    backup_day=${backup_day:-0}
    read -p "What time? (HH:MM, 24hr format) [02:00]: " backup_time
    backup_time=${backup_time:-02:00}
    hour=${backup_time%:*}
    minute=${backup_time#*:}
    cron_schedule="$minute $hour * * $backup_day"
    schedule_desc="weekly on $(if [ $backup_day -eq 0 ]; then echo "Sunday"; elif [ $backup_day -eq 1 ]; then echo "Monday"; elif [ $backup_day -eq 2 ]; then echo "Tuesday"; elif [ $backup_day -eq 3 ]; then echo "Wednesday"; elif [ $backup_day -eq 4 ]; then echo "Thursday"; elif [ $backup_day -eq 5 ]; then echo "Friday"; else echo "Saturday"; fi) at $backup_time"
    ;;
  3)
    read -p "Which day of the month? (1-28) [1]: " backup_day
    backup_day=${backup_day:-1}
    read -p "What time? (HH:MM, 24hr format) [02:00]: " backup_time
    backup_time=${backup_time:-02:00}
    hour=${backup_time%:*}
    minute=${backup_time#*:}
    cron_schedule="$minute $hour $backup_day * *"
    schedule_desc="monthly on day $backup_day at $backup_time"
    ;;
  4)
    read -p "Enter custom cron schedule (minute hour day month weekday): " cron_schedule
    schedule_desc="based on custom schedule: $cron_schedule"
    ;;
  *)
    echo -e "${RED}Invalid option. Exiting.${NC}"
    exit 1
    ;;
esac

# Ask for retention period
read -p "How many days to retain backups? [7]: " retention_days
retention_days=${retention_days:-7}

# Update retention period in backup.sh
sed -i '' "s/RETENTION_DAYS=7/RETENTION_DAYS=$retention_days/g" ./scripts/backup.sh

# Create backup directories
mkdir -p ./backups/databases
mkdir -p ./backups/volumes

# Create a temporary file for the crontab
TEMP_CRON=$(mktemp)

# Export current crontab to the temporary file
crontab -l > "$TEMP_CRON" 2>/dev/null

# Check if the backup cron job already exists
if grep -q "$BACKUP_SCRIPT_PATH" "$TEMP_CRON"; then
  echo -e "${YELLOW}Backup cron job already exists. Updating...${NC}"
  sed -i '' "/$(basename $BACKUP_SCRIPT_PATH)/d" "$TEMP_CRON"
fi

# Add the backup cron job
echo "$cron_schedule cd $PROJECT_DIR && $BACKUP_SCRIPT_PATH >> ./backups/backup.log 2>&1" >> "$TEMP_CRON"

# Install the new crontab
crontab "$TEMP_CRON"
  
echo -e "${GREEN}Backup cron job added. Backups will run $schedule_desc.${NC}"
echo -e "${GREEN}Backups will be retained for $retention_days days.${NC}"

# Clean up the temporary file
rm "$TEMP_CRON"

echo -e "\n${BLUE}====== Setup Complete ======${NC}"
echo -e "${GREEN}You can run backups manually with: ./scripts/backup.sh${NC}"
echo -e "${GREEN}You can restore from backups with: ./scripts/restore.sh --help${NC}"
echo -e "${GREEN}Backup logs will be saved to: backups/backup.log${NC}"
