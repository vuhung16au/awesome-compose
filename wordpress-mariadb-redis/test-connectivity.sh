#!/bin/bash
# Test Connectivity Script for WordPress with MariaDB and Redis
# This script checks the health and connectivity of all services in the stack

# Set color codes for better visibility
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}====== WordPress, MariaDB, Redis, and phpMyAdmin Connectivity Test ======${NC}\n"

# Check if Docker is running
echo -e "${YELLOW}Checking if Docker is running...${NC}"
if ! docker info >/dev/null 2>&1; then
  echo -e "${RED}Error: Docker is not running.${NC}"
  exit 1
fi
echo -e "${GREEN}Docker is running.${NC}\n"

# Check if the Docker Compose stack is running
echo -e "${YELLOW}Checking if containers are running...${NC}"
if [ "$(docker ps -q --filter name=wordpress-mariadb-redis)" == "" ]; then
  echo -e "${RED}Error: Containers are not running. Please start the stack with 'docker compose up -d'.${NC}"
  exit 1
fi

# Display all running containers in the stack
docker compose ps

# Test WordPress service
echo -e "\n${YELLOW}Testing WordPress service...${NC}"
WP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80)
if [ "$WP_RESPONSE" == "200" ] || [ "$WP_RESPONSE" == "302" ]; then
  echo -e "${GREEN}WordPress is accessible at http://localhost:80 (HTTP $WP_RESPONSE)${NC}"
else
  echo -e "${RED}WordPress is not accessible. Got HTTP $WP_RESPONSE${NC}"
fi

# Test phpMyAdmin service
echo -e "\n${YELLOW}Testing phpMyAdmin service...${NC}"
PMA_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080)
if [ "$PMA_RESPONSE" == "200" ] || [ "$PMA_RESPONSE" == "302" ]; then
  echo -e "${GREEN}phpMyAdmin is accessible at http://localhost:8080 (HTTP $PMA_RESPONSE)${NC}"
else
  echo -e "${RED}phpMyAdmin is not accessible. Got HTTP $PMA_RESPONSE${NC}"
fi

# Test MariaDB connection
echo -e "\n${YELLOW}Testing MariaDB connection from WordPress container...${NC}"
DB_TEST=$(docker exec wordpress-mariadb-redis-wordpress-1 sh -c "php -r '\$conn = new mysqli(\"mariadb\", \"wordpress\", \"wordpress\", \"wordpress\"); echo \$conn->connect_error ? \"ERROR: \" . \$conn->connect_error : \"SUCCESS: Connected to MariaDB\";'")
echo -e "${GREEN}$DB_TEST${NC}"

# Test Redis connection
echo -e "\n${YELLOW}Testing Redis connection...${NC}"
REDIS_TEST=$(docker exec wordpress-mariadb-redis-redis-1 redis-cli -a wordpress_redis ping)
if [ "$REDIS_TEST" == "PONG" ]; then
  echo -e "${GREEN}Successfully connected to Redis (got '$REDIS_TEST' response)${NC}"
else
  echo -e "${RED}Failed to connect to Redis. Response: $REDIS_TEST${NC}"
fi

# Check if Redis PHP module is installed
echo -e "\n${YELLOW}Checking Redis PHP module in WordPress container...${NC}"
REDIS_PHP=$(docker exec wordpress-mariadb-redis-wordpress-1 php82 -m | grep -c redis)
if [ "$REDIS_PHP" -gt 0 ]; then
  echo -e "${GREEN}Redis PHP module is installed in WordPress container${NC}"
else
  echo -e "${RED}Redis PHP module is NOT installed in WordPress container${NC}"
fi

# Check Redis Object Cache plugin
echo -e "\n${YELLOW}Checking Redis Object Cache plugin installation...${NC}"
REDIS_PLUGIN=$(docker exec wordpress-mariadb-redis-wordpress-1 sh -c "[ -d /var/www/html/wp-content/plugins/redis-cache ] && echo 'INSTALLED' || echo 'NOT INSTALLED'")
if [ "$REDIS_PLUGIN" == "INSTALLED" ]; then
  echo -e "${GREEN}Redis Object Cache plugin is installed${NC}"
else
  echo -e "${RED}Redis Object Cache plugin is NOT installed${NC}"
  echo -e "${YELLOW}Installing Redis Object Cache plugin...${NC}"
  docker exec wordpress-mariadb-redis-wordpress-1 sh -c "mkdir -p /var/www/html/wp-content/plugins/ && curl -o /tmp/redis-cache.zip -L https://downloads.wordpress.org/plugin/redis-cache.latest-stable.zip && apk add --no-cache unzip && unzip -o /tmp/redis-cache.zip -d /var/www/html/wp-content/plugins/ && rm /tmp/redis-cache.zip && chown -R apache:apache /var/www/html/wp-content/plugins/"
  echo -e "${GREEN}Redis Object Cache plugin has been installed${NC}"
fi

# Check Apache logs for errors
echo -e "\n${YELLOW}Checking for Apache errors in WordPress container...${NC}"
APACHE_ERRORS=$(docker exec wordpress-mariadb-redis-wordpress-1 sh -c "grep -i error /var/log/apache2/error.log | grep -v 'AH00558\|AH02282\|pid file' | tail -5")
if [ -z "$APACHE_ERRORS" ]; then
  echo -e "${GREEN}No significant errors found in Apache logs${NC}"
else
  echo -e "${RED}Errors found in Apache logs:${NC}"
  echo "$APACHE_ERRORS"
fi

# Check PHP logs for errors
echo -e "\n${YELLOW}Checking for PHP errors in WordPress container...${NC}"
PHP_ERRORS=$(docker exec wordpress-mariadb-redis-wordpress-1 sh -c "grep -i error /var/log/php82/error.log | grep -v 'NOTICE' | tail -5")
if [ -z "$PHP_ERRORS" ]; then
  echo -e "${GREEN}No significant errors found in PHP logs${NC}"
else
  echo -e "${RED}Errors found in PHP logs:${NC}"
  echo "$PHP_ERRORS"
fi

# Print WordPress configuration details
echo -e "\n${YELLOW}Checking WordPress configuration...${NC}"
docker exec wordpress-mariadb-redis-wordpress-1 sh -c "grep -E 'WP_REDIS|DB_' /var/www/html/wp-config.php"

echo -e "\n${BLUE}====== Connectivity Test Completed ======${NC}"
echo -e "If all tests passed, your WordPress with MariaDB and Redis setup is working properly."
echo -e "Complete the WordPress installation at http://localhost:80 and activate the Redis Object Cache plugin in the WordPress admin panel."
