# Backup and Restore

This document outlines the backup and restore procedures for the WordPress MariaDB Redis stack.

## Backup Strategy

The stack includes automated backup scripts for MariaDB databases and all persistent volumes (WordPress uploads, Redis data, and Grafana data). The backup scripts are located in the `scripts/` directory.

### What Gets Backed Up

1. **MariaDB Database**: All databases are dumped and compressed
2. **WordPress Uploads**: The shared uploads directory is archived and compressed
3. **Redis Data**: Both Redis instances' data are archived and compressed
4. **Grafana Data**: Dashboards, users, and settings are archived and compressed

### Backup Retention

By default, backups are retained for 7 days, after which they are automatically removed to prevent disk space issues. This retention period is configurable in the setup-cron.sh script.

## Setting Up Automated Backups

There are two ways to configure automated backups:

### Option 1: Using the Docker-based Backup Service (Recommended)

The stack includes a dedicated backup service in `compose.yaml` that automatically handles scheduled backups:

```bash
# Update backup settings in .env file (optional)
echo "BACKUP_SCHEDULE=0 2 * * *" >> .env  # Daily at 2:00 AM
echo "BACKUP_RETENTION_DAYS=7" >> .env    # Keep backups for 7 days
echo "TIMEZONE=UTC" >> .env              # Timezone for backups

# Start or restart the stack with the backup service
docker compose up -d
```

All backups will be stored in the `backups/` directory of your project.

### Option 2: Using Host System Cron (Alternative)

You can also set up backup jobs directly on the host system:

```bash
# Make sure scripts are executable
chmod +x scripts/backup.sh scripts/restore.sh scripts/setup-cron.sh

# Run the setup script with sudo (needed for crontab setup)
sudo ./scripts/setup-cron.sh
```

The setup script will guide you through setting up a cron job with the following options:

1. **Frequency**: Daily, weekly, monthly, or custom schedule
2. **Time**: When the backups should run (default: 2:00 AM)
3. **Retention**: How many days to keep backups (default: 7 days)

All backups are stored in the `backups/` directory, organized by type:
- `backups/databases/`: Database dumps
- `backups/volumes/`: Volume backups (WordPress uploads, Redis data, Grafana data)

## Running Manual Backups

To run a manual backup:

```bash
./scripts/backup.sh
```

This will create timestamped backups in the `backups/` directory.

## Restoring from Backup

The restore script allows you to restore individual components from backups:

```bash
# List available backups
./scripts/restore.sh --list

# Restore a database
./scripts/restore.sh --db backups/databases/mariadb_all_2023-05-24_15-30-00.sql.gz

# Restore WordPress uploads
./scripts/restore.sh --uploads backups/volumes/wordpress_uploads_2023-05-24_15-30-00.tar.gz

# Restore Redis instance 1
./scripts/restore.sh --redis1 backups/volumes/redis1_data_2023-05-24_15-30-00.tar.gz

# Restore Redis instance 2
./scripts/restore.sh --redis2 backups/volumes/redis2_data_2023-05-24_15-30-00.tar.gz

# Restore Grafana data
./scripts/restore.sh --grafana backups/volumes/grafana_data_2023-05-24_15-30-00.tar.gz
```

## Offsite Backups (Optional)

For production environments, it's recommended to store backups offsite. The backup script contains commented sections for uploading backups to cloud storage services like AWS S3 or Google Cloud Storage.

To enable this feature:

1. Install and configure the appropriate cloud provider CLI tool
2. Uncomment and customize the relevant section in `scripts/backup.sh`
3. Ensure the appropriate credentials are available to the backup process

Example for AWS S3 (uncomment in the script):

```bash
# Upload to AWS S3
aws s3 sync "$BACKUP_DIR" "s3://your-bucket/backups/"
```

## Backup Monitoring

Backup logs are stored in `backups/backup.log`. It's recommended to check these logs periodically to ensure backups are completing successfully.

