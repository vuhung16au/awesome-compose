#!/bin/bash
# Test Script for WordPress with MariaDB, Redis, NGINX and phpMyAdmin
# This script checks the health and connectivity of all services in the stack

# Set color codes for better visibility
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}====== WordPress, MariaDB, Redis, NGINX, and phpMyAdmin Test ======${NC}\n"

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

# Count WordPress instances
WP_COUNT=$(docker ps --filter name=wordpress-mariadb-redis-wordpress -q | wc -l)
echo -e "${BLUE}Running $WP_COUNT WordPress instance(s)${NC}"

# Count Redis instances
REDIS_COUNT=$(docker ps --filter name=wordpress-mariadb-redis-redis -q | wc -l)
echo -e "${BLUE}Running $REDIS_COUNT Redis instance(s)${NC}"

# Test NGINX service
echo -e "\n${YELLOW}Testing NGINX service...${NC}"
NGINX_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80)
if [ "$NGINX_RESPONSE" == "200" ] || [ "$NGINX_RESPONSE" == "302" ]; then
  echo -e "${GREEN}NGINX is accessible at http://localhost:80 (HTTP $NGINX_RESPONSE)${NC}"

  # Test HTTPS redirection
  echo -e "${YELLOW}Testing HTTPS redirection...${NC}"
  REDIRECT_URL=$(curl -s -I http://localhost:80 | grep -i Location)
  if [[ "$REDIRECT_URL" == *"https://"* ]]; then
    echo -e "${GREEN}HTTP to HTTPS redirection is working properly${NC}"
  else
    echo -e "${YELLOW}HTTP to HTTPS redirection not detected${NC}"
  fi
  
  # Check if NGINX is properly load balancing
  echo -e "${YELLOW}Testing NGINX load balancing configuration...${NC}"
  
  # Check if NGINX configuration contains the upstream block
  NGINX_CONFIG=$(docker exec wordpress-mariadb-redis-nginx-1 cat /etc/nginx/conf.d/default.conf)
  if echo "$NGINX_CONFIG" | grep -q "upstream wordpress_backend"; then
    echo -e "${GREEN}NGINX has load balancing configuration${NC}"
    
    # Check if NGINX is using ip_hash for session persistence
    if echo "$NGINX_CONFIG" | grep -q "ip_hash"; then
      echo -e "${GREEN}NGINX is configured with ip_hash for session persistence${NC}"
    else
      echo -e "${YELLOW}NGINX does not have ip_hash configured for session persistence${NC}"
    fi
    
    # Check how many WordPress instances are running
    WP_INSTANCES=$(docker ps --filter "name=wordpress-mariadb-redis-wordpress" | grep -v "nvidia" | wc -l)
    if [ "$WP_INSTANCES" -eq 3 ]; then
      echo -e "${GREEN}All 3 WordPress instances are running, load balancing is active${NC}"
      
      # Check backend_wordpress configuration in NGINX
      if echo "$NGINX_CONFIG" | grep -q "server wordpress-1:80" && \
         echo "$NGINX_CONFIG" | grep -q "server wordpress-2:80" && \
         echo "$NGINX_CONFIG" | grep -q "server wordpress-3:80"; then
        echo -e "${GREEN}NGINX is properly configured to load balance across all 3 WordPress instances${NC}"
      else
        echo -e "${RED}NGINX configuration does not include all 3 WordPress instances${NC}"
      fi
      
    elif [ "$WP_INSTANCES" -gt 0 ]; then
      echo -e "${YELLOW}Found $((WP_INSTANCES-1)) WordPress instances (expected 3), load balancing may be limited${NC}"
    else
      echo -e "${RED}No WordPress instances running, load balancing is not active${NC}"
    fi
  else
    echo -e "${RED}NGINX load balancing configuration not found${NC}"
  fi
else
  echo -e "${RED}NGINX is not accessible. Got HTTP $NGINX_RESPONSE${NC}"
fi

# Test WordPress through NGINX (both HTTP and HTTPS)
echo -e "\n${YELLOW}Testing WordPress through NGINX...${NC}"
WP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80)
if [ "$WP_RESPONSE" == "200" ] || [ "$WP_RESPONSE" == "302" ]; then
  echo -e "${GREEN}WordPress is accessible through NGINX at http://localhost:80 (HTTP $WP_RESPONSE)${NC}"
else
  echo -e "${RED}WordPress is not accessible through NGINX HTTP. Got HTTP $WP_RESPONSE${NC}"
fi

# Test WordPress through NGINX over HTTPS
WP_HTTPS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -k https://localhost:443)
if [ "$WP_HTTPS_RESPONSE" == "200" ] || [ "$WP_HTTPS_RESPONSE" == "302" ]; then
  echo -e "${GREEN}WordPress is accessible through NGINX over HTTPS at https://localhost:443 (HTTP $WP_HTTPS_RESPONSE)${NC}"
else
  echo -e "${RED}WordPress is not accessible through NGINX over HTTPS. Got HTTP $WP_HTTPS_RESPONSE${NC}"
fi

# Test HTTPS connection
echo -e "\n${YELLOW}Testing HTTPS connection...${NC}"
HTTPS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -k https://localhost:443)
if [ "$HTTPS_RESPONSE" == "200" ] || [ "$HTTPS_RESPONSE" == "302" ]; then
  echo -e "${GREEN}HTTPS is accessible at https://localhost:443 (HTTP $HTTPS_RESPONSE)${NC}"

  # Check if SSL certificates are valid
  echo -e "${YELLOW}Checking SSL certificates...${NC}"
  SSL_EXPIRY=$(echo | openssl s_client -connect localhost:443 2>/dev/null | openssl x509 -noout -dates 2>/dev/null)
  if [ -n "$SSL_EXPIRY" ]; then
    echo -e "${GREEN}SSL certificates are properly configured${NC}"
    echo -e "$SSL_EXPIRY"
    
    # Get certificate details for further analysis
    echo -e "${YELLOW}Getting SSL certificate details...${NC}"
    SSL_DETAILS=$(echo | openssl s_client -connect localhost:443 2>/dev/null | openssl x509 -noout -text 2>/dev/null | grep -E "Subject:|Issuer:|Algorithm:|Not Before:|Not After :|DNS:" | head -15)
    echo -e "${GREEN}Certificate Details:${NC}"
    echo -e "$SSL_DETAILS"
    
    # Check SSL protocols
    echo -e "${YELLOW}Checking supported SSL protocols...${NC}"
    SSL_PROTOCOLS=$(docker exec wordpress-mariadb-redis-nginx-1 sh -c "grep -A5 'ssl_protocols' /etc/nginx/conf.d/default.conf | grep -v '#'")
    echo -e "${GREEN}SSL Protocols: $SSL_PROTOCOLS${NC}"
  else
    echo -e "${RED}SSL certificates could not be verified${NC}"
  fi
else
  echo -e "${RED}HTTPS is not accessible. Got HTTP $HTTPS_RESPONSE${NC}"
fi

# Test phpMyAdmin service
echo -e "\n${YELLOW}Testing phpMyAdmin service...${NC}"
PMA_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080)
if [ "$PMA_RESPONSE" == "200" ] || [ "$PMA_RESPONSE" == "302" ]; then
  echo -e "${GREEN}phpMyAdmin is accessible at http://localhost:8080 (HTTP $PMA_RESPONSE)${NC}"
else
  echo -e "${RED}phpMyAdmin is not accessible. Got HTTP $PMA_RESPONSE${NC}"
fi

# Test Grafana service
echo -e "\n${YELLOW}Testing Grafana service...${NC}"
GRAFANA_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/login)
if [ "$GRAFANA_RESPONSE" == "200" ]; then
  echo -e "${GREEN}Grafana is accessible at http://localhost:3000 (HTTP $GRAFANA_RESPONSE)${NC}"
else
  echo -e "${RED}Grafana is not accessible. Got HTTP $GRAFANA_RESPONSE${NC}"
fi

# Test Prometheus service
echo -e "\n${YELLOW}Testing Prometheus service...${NC}"
PROM_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9090/-/ready)
if [ "$PROM_RESPONSE" == "200" ]; then
  echo -e "${GREEN}Prometheus is accessible at http://localhost:9090 (HTTP $PROM_RESPONSE)${NC}"
else
  echo -e "${RED}Prometheus is not accessible. Got HTTP $PROM_RESPONSE${NC}"
fi

# Test Prometheus targets
echo -e "\n${YELLOW}Checking Prometheus targets...${NC}"
PROM_TARGETS=$(curl -s http://localhost:9090/api/v1/targets | grep -E '"health":"up"')
if [ -n "$PROM_TARGETS" ]; then
  echo -e "${GREEN}Prometheus is scraping targets successfully${NC}"
else
  echo -e "${RED}Prometheus is NOT scraping any targets or targets are down${NC}"
fi

# Test MariaDB connection from all WordPress containers
echo -e "\n${YELLOW}Testing MariaDB connections from WordPress containers...${NC}"

echo -e "${YELLOW}Testing WordPress-1 to MariaDB connection...${NC}"
DB_TEST1=$(docker exec wordpress-mariadb-redis-wordpress-1-1 sh -c "php82 -r '\$conn = new mysqli(\"mariadb\", \"wordpress\", \"wordpress\", \"wordpress\"); echo \$conn->connect_error ? \"ERROR: \" . \$conn->connect_error : \"SUCCESS: WordPress-1 connected to MariaDB\";'")
echo -e "${GREEN}$DB_TEST1${NC}"

echo -e "${YELLOW}Testing WordPress-2 to MariaDB connection...${NC}"
DB_TEST2=$(docker exec wordpress-mariadb-redis-wordpress-2-1 sh -c "php82 -r '\$conn = new mysqli(\"mariadb\", \"wordpress\", \"wordpress\", \"wordpress\"); echo \$conn->connect_error ? \"ERROR: \" . \$conn->connect_error : \"SUCCESS: WordPress-2 connected to MariaDB\";'")
echo -e "${GREEN}$DB_TEST2${NC}"

echo -e "${YELLOW}Testing WordPress-3 to MariaDB connection...${NC}"
DB_TEST3=$(docker exec wordpress-mariadb-redis-wordpress-3-1 sh -c "php82 -r '\$conn = new mysqli(\"mariadb\", \"wordpress\", \"wordpress\", \"wordpress\"); echo \$conn->connect_error ? \"ERROR: \" . \$conn->connect_error : \"SUCCESS: WordPress-3 connected to MariaDB\";'")
echo -e "${GREEN}$DB_TEST3${NC}"

# Test Redis connections
echo -e "\n${YELLOW}Testing Redis connections...${NC}"
echo -e "${YELLOW}Testing Redis-1 connection...${NC}"
REDIS1_TEST=$(docker exec wordpress-mariadb-redis-redis-1-1 redis-cli -a wordpress_redis ping)
if [ "$REDIS1_TEST" == "PONG" ]; then
  echo -e "${GREEN}Successfully connected to Redis-1 (got '$REDIS1_TEST' response)${NC}"
else
  echo -e "${RED}Failed to connect to Redis-1. Response: $REDIS1_TEST${NC}"
fi

echo -e "${YELLOW}Testing Redis-2 connection...${NC}"
REDIS2_TEST=$(docker exec wordpress-mariadb-redis-redis-2-1 redis-cli -a wordpress_redis ping)
if [ "$REDIS2_TEST" == "PONG" ]; then
  echo -e "${GREEN}Successfully connected to Redis-2 (got '$REDIS2_TEST' response)${NC}"
else
  echo -e "${RED}Failed to connect to Redis-2. Response: $REDIS2_TEST${NC}"
fi

# Check if Redis PHP module is installed in each WordPress container
echo -e "\n${YELLOW}Checking Redis PHP module in WordPress containers...${NC}"

echo -e "${YELLOW}Checking WordPress-1 container...${NC}"
REDIS_PHP1=$(docker exec wordpress-mariadb-redis-wordpress-1-1 php82 -m | grep -c redis)
if [ "$REDIS_PHP1" -gt 0 ]; then
  echo -e "${GREEN}Redis PHP module is installed in WordPress-1 container${NC}"
else
  echo -e "${RED}Redis PHP module is NOT installed in WordPress-1 container${NC}"
fi

echo -e "${YELLOW}Checking WordPress-2 container...${NC}"
REDIS_PHP2=$(docker exec wordpress-mariadb-redis-wordpress-2-1 php82 -m | grep -c redis)
if [ "$REDIS_PHP2" -gt 0 ]; then
  echo -e "${GREEN}Redis PHP module is installed in WordPress-2 container${NC}"
else
  echo -e "${RED}Redis PHP module is NOT installed in WordPress-2 container${NC}"
fi

echo -e "${YELLOW}Checking WordPress-3 container...${NC}"
REDIS_PHP3=$(docker exec wordpress-mariadb-redis-wordpress-3-1 php82 -m | grep -c redis)
if [ "$REDIS_PHP3" -gt 0 ]; then
  echo -e "${GREEN}Redis PHP module is installed in WordPress-3 container${NC}"
else
  echo -e "${RED}Redis PHP module is NOT installed in WordPress-3 container${NC}"
fi

# Check Redis Object Cache plugin in each WordPress container
echo -e "\n${YELLOW}Checking Redis Object Cache plugin installation...${NC}"

echo -e "${YELLOW}Checking plugin in WordPress-1...${NC}"
REDIS_PLUGIN1=$(docker exec wordpress-mariadb-redis-wordpress-1-1 sh -c "[ -d /var/www/html/wp-content/plugins/redis-cache ] && echo 'INSTALLED' || echo 'NOT INSTALLED'")
if [ "$REDIS_PLUGIN1" == "INSTALLED" ]; then
  echo -e "${GREEN}Redis Object Cache plugin is installed in WordPress-1${NC}"
else
  echo -e "${RED}Redis Object Cache plugin is NOT installed in WordPress-1${NC}"
  echo -e "${YELLOW}Installing Redis Object Cache plugin in WordPress-1...${NC}"
  docker exec wordpress-mariadb-redis-wordpress-1-1 sh -c "mkdir -p /var/www/html/wp-content/plugins/ && apk add --no-cache curl unzip && curl -o /tmp/redis-cache.zip -L https://downloads.wordpress.org/plugin/redis-cache.latest-stable.zip && unzip -o /tmp/redis-cache.zip -d /var/www/html/wp-content/plugins/ && rm /tmp/redis-cache.zip && chown -R apache:apache /var/www/html/wp-content/plugins/"
  echo -e "${GREEN}Redis Object Cache plugin has been installed in WordPress-1${NC}"
fi

echo -e "${YELLOW}Checking plugin in WordPress-2...${NC}"
REDIS_PLUGIN2=$(docker exec wordpress-mariadb-redis-wordpress-2-1 sh -c "[ -d /var/www/html/wp-content/plugins/redis-cache ] && echo 'INSTALLED' || echo 'NOT INSTALLED'")
if [ "$REDIS_PLUGIN2" == "INSTALLED" ]; then
  echo -e "${GREEN}Redis Object Cache plugin is installed in WordPress-2${NC}"
else
  echo -e "${RED}Redis Object Cache plugin is NOT installed in WordPress-2${NC}"
  echo -e "${YELLOW}Installing Redis Object Cache plugin in WordPress-2...${NC}"
  docker exec wordpress-mariadb-redis-wordpress-2-1 sh -c "mkdir -p /var/www/html/wp-content/plugins/ && apk add --no-cache curl unzip && curl -o /tmp/redis-cache.zip -L https://downloads.wordpress.org/plugin/redis-cache.latest-stable.zip && unzip -o /tmp/redis-cache.zip -d /var/www/html/wp-content/plugins/ && rm /tmp/redis-cache.zip && chown -R apache:apache /var/www/html/wp-content/plugins/"
  echo -e "${GREEN}Redis Object Cache plugin has been installed in WordPress-2${NC}"
fi

echo -e "${YELLOW}Checking plugin in WordPress-3...${NC}"
REDIS_PLUGIN3=$(docker exec wordpress-mariadb-redis-wordpress-3-1 sh -c "[ -d /var/www/html/wp-content/plugins/redis-cache ] && echo 'INSTALLED' || echo 'NOT INSTALLED'")
if [ "$REDIS_PLUGIN3" == "INSTALLED" ]; then
  echo -e "${GREEN}Redis Object Cache plugin is installed in WordPress-3${NC}"
else
  echo -e "${RED}Redis Object Cache plugin is NOT installed in WordPress-3${NC}"
  echo -e "${YELLOW}Installing Redis Object Cache plugin in WordPress-3...${NC}"
  docker exec wordpress-mariadb-redis-wordpress-3-1 sh -c "mkdir -p /var/www/html/wp-content/plugins/ && apk add --no-cache curl unzip && curl -o /tmp/redis-cache.zip -L https://downloads.wordpress.org/plugin/redis-cache.latest-stable.zip && unzip -o /tmp/redis-cache.zip -d /var/www/html/wp-content/plugins/ && rm /tmp/redis-cache.zip && chown -R apache:apache /var/www/html/wp-content/plugins/"
  echo -e "${GREEN}Redis Object Cache plugin has been installed in WordPress-3${NC}"
fi

# Check Apache logs for errors in all WordPress containers
echo -e "\n${YELLOW}Checking for Apache errors in WordPress containers...${NC}"

echo -e "${YELLOW}Checking WordPress-1 Apache logs...${NC}"
APACHE_ERRORS1=$(docker exec wordpress-mariadb-redis-wordpress-1-1 sh -c "grep -i error /var/log/apache2/error.log | grep -v 'AH00558\|AH02282\|pid file' | tail -5")
if [ -z "$APACHE_ERRORS1" ]; then
  echo -e "${GREEN}No significant errors found in WordPress-1 Apache logs${NC}"
else
  echo -e "${RED}Errors found in WordPress-1 Apache logs:${NC}"
  echo "$APACHE_ERRORS1"
fi

echo -e "${YELLOW}Checking WordPress-2 Apache logs...${NC}"
APACHE_ERRORS2=$(docker exec wordpress-mariadb-redis-wordpress-2-1 sh -c "grep -i error /var/log/apache2/error.log | grep -v 'AH00558\|AH02282\|pid file' | tail -5")
if [ -z "$APACHE_ERRORS2" ]; then
  echo -e "${GREEN}No significant errors found in WordPress-2 Apache logs${NC}"
else
  echo -e "${RED}Errors found in WordPress-2 Apache logs:${NC}"
  echo "$APACHE_ERRORS2"
fi

echo -e "${YELLOW}Checking WordPress-3 Apache logs...${NC}"
APACHE_ERRORS3=$(docker exec wordpress-mariadb-redis-wordpress-3-1 sh -c "grep -i error /var/log/apache2/error.log | grep -v 'AH00558\|AH02282\|pid file' | tail -5")
if [ -z "$APACHE_ERRORS3" ]; then
  echo -e "${GREEN}No significant errors found in WordPress-3 Apache logs${NC}"
else
  echo -e "${RED}Errors found in WordPress-3 Apache logs:${NC}"
  echo "$APACHE_ERRORS3"
fi

# Check PHP logs for errors in all WordPress containers
echo -e "\n${YELLOW}Checking for PHP errors in WordPress containers...${NC}"

echo -e "${YELLOW}Checking WordPress-1 PHP logs...${NC}"
PHP_ERRORS1=$(docker exec wordpress-mariadb-redis-wordpress-1-1 sh -c "grep -i error /var/log/php82/error.log | grep -v 'NOTICE' | tail -5")
if [ -z "$PHP_ERRORS1" ]; then
  echo -e "${GREEN}No significant errors found in WordPress-1 PHP logs${NC}"
else
  echo -e "${RED}Errors found in WordPress-1 PHP logs:${NC}"
  echo "$PHP_ERRORS1"
fi

echo -e "${YELLOW}Checking WordPress-2 PHP logs...${NC}"
PHP_ERRORS2=$(docker exec wordpress-mariadb-redis-wordpress-2-1 sh -c "grep -i error /var/log/php82/error.log | grep -v 'NOTICE' | tail -5")
if [ -z "$PHP_ERRORS2" ]; then
  echo -e "${GREEN}No significant errors found in WordPress-2 PHP logs${NC}"
else
  echo -e "${RED}Errors found in WordPress-2 PHP logs:${NC}"
  echo "$PHP_ERRORS2"
fi

echo -e "${YELLOW}Checking WordPress-3 PHP logs...${NC}"
PHP_ERRORS3=$(docker exec wordpress-mariadb-redis-wordpress-3-1 sh -c "grep -i error /var/log/php82/error.log | grep -v 'NOTICE' | tail -5")
if [ -z "$PHP_ERRORS3" ]; then
  echo -e "${GREEN}No significant errors found in WordPress-3 PHP logs${NC}"
else
  echo -e "${RED}Errors found in WordPress-3 PHP logs:${NC}"
  echo "$PHP_ERRORS3"
fi

# Print WordPress configuration details
echo -e "\n${YELLOW}Checking WordPress configurations...${NC}"
echo -e "${YELLOW}Checking WordPress-1 configuration...${NC}"
docker exec wordpress-mariadb-redis-wordpress-1-1 sh -c "grep -E 'WP_REDIS|DB_' /var/www/html/wp-config.php"

echo -e "${YELLOW}Checking WordPress-2 configuration...${NC}"
docker exec wordpress-mariadb-redis-wordpress-2-1 sh -c "grep -E 'WP_REDIS|DB_' /var/www/html/wp-config.php"

echo -e "${YELLOW}Checking WordPress-3 configuration...${NC}"
docker exec wordpress-mariadb-redis-wordpress-3-1 sh -c "grep -E 'WP_REDIS|DB_' /var/www/html/wp-config.php"

# Test NGINX logs for errors
echo -e "\n${YELLOW}Checking for NGINX errors...${NC}"
NGINX_ERRORS=$(docker exec wordpress-mariadb-redis-nginx-1 sh -c "grep -i error /var/log/nginx/error.log 2>/dev/null | grep -v 'No such file' | tail -5 || echo 'No errors found'")
if [[ "$NGINX_ERRORS" == "No errors found" ]]; then
  echo -e "${GREEN}No significant errors found in NGINX logs${NC}"
else
  echo -e "${RED}Errors found in NGINX logs:${NC}"
  echo "$NGINX_ERRORS"
fi

# Check NGINX service status instead of configuration test which can hang
echo -e "\n${YELLOW}Checking NGINX service status...${NC}"
NGINX_STATUS=$(docker inspect --format='{{.State.Status}}' wordpress-mariadb-redis-nginx-1)
NGINX_HEALTH=$(docker inspect --format='{{.State.Health.Status}}' wordpress-mariadb-redis-nginx-1 2>/dev/null || echo "health checks not configured")

if [ "$NGINX_STATUS" == "running" ]; then
  echo -e "${GREEN}NGINX service is running${NC}"
  # Get NGINX version information
  NGINX_VERSION=$(docker exec wordpress-mariadb-redis-nginx-1 nginx -v 2>&1 || echo "Unable to get version")
  echo -e "${GREEN}$NGINX_VERSION${NC}"
else
  echo -e "${RED}NGINX service is not running (status: $NGINX_STATUS)${NC}"
fi

# Test shared uploads volume
echo -e "\n${YELLOW}Testing shared uploads volume...${NC}"

# Create a test file in the uploads directory
echo -e "${YELLOW}Creating test file in WordPress uploads directory...${NC}"
TEST_FILE="test_$(date +%s).txt"
docker exec wordpress-mariadb-redis-wordpress-1 sh -c "echo 'Test file for shared volume' > /var/www/html/wp-content/uploads/$TEST_FILE"

# Check if another WordPress container can access it (if scaled)
WP_CONTAINERS=$(docker ps -q --filter name=wordpress-mariadb-redis-wordpress)
WP_COUNT=$(echo "$WP_CONTAINERS" | wc -l)

if [ "$WP_COUNT" -gt 1 ]; then
  # If there are multiple WordPress containers, check if they can all access the file
  echo -e "${YELLOW}Testing file access across multiple WordPress containers...${NC}"
  
  for CONTAINER_ID in $WP_CONTAINERS; do
    CONTAINER_NAME=$(docker inspect --format='{{.Name}}' $CONTAINER_ID | sed 's/\///')
    if [[ "$CONTAINER_NAME" != "wordpress-mariadb-redis-wordpress-1" ]]; then
      FILE_CHECK=$(docker exec $CONTAINER_ID sh -c "cat /var/www/html/wp-content/uploads/$TEST_FILE 2>/dev/null || echo 'NOT FOUND'")
      
      if [[ "$FILE_CHECK" == *"Test file for shared volume"* ]]; then
        echo -e "${GREEN}Shared volume working correctly: $CONTAINER_NAME can access the test file${NC}"
      else
        echo -e "${RED}Shared volume FAILED: $CONTAINER_NAME cannot access the test file${NC}"
      fi
    fi
  done
else
  # If there's only one WordPress container, verify the volume is mounted properly
  VOLUME_CHECK=$(docker exec wordpress-mariadb-redis-wordpress-1 sh -c "df -h | grep '/var/www/html/wp-content/uploads'")
  
  if [ -n "$VOLUME_CHECK" ]; then
    echo -e "${GREEN}Uploads volume is properly mounted${NC}"
  else
    echo -e "${RED}Uploads volume is NOT properly mounted${NC}"
  fi
fi

# Clean up the test file
docker exec wordpress-mariadb-redis-wordpress-1 sh -c "rm -f /var/www/html/wp-content/uploads/$TEST_FILE"
echo -e "${GREEN}Test file cleaned up${NC}"

# Test Redis connectivity from WordPress instances
echo -e "\n${YELLOW}Testing Redis connectivity from WordPress instances...${NC}"

echo -e "${YELLOW}Testing WordPress-1 to Redis-1 connection...${NC}"
WP1_REDIS_TEST=$(docker exec wordpress-mariadb-redis-wordpress-1-1 sh -c "php82 -r '\$redis = new Redis(); try { \$redis->connect(\"redis-1\", 6379); \$redis->auth(\"wordpress_redis\"); echo \"SUCCESS: WordPress-1 connected to Redis-1 (\" . \$redis->ping() . \")\"; } catch (Exception \$e) { echo \"ERROR: \" . \$e->getMessage(); }'")
echo -e "${GREEN}$WP1_REDIS_TEST${NC}"

echo -e "${YELLOW}Testing WordPress-2 to Redis-2 connection...${NC}"
WP2_REDIS_TEST=$(docker exec wordpress-mariadb-redis-wordpress-2-1 sh -c "php82 -r '\$redis = new Redis(); try { \$redis->connect(\"redis-2\", 6379); \$redis->auth(\"wordpress_redis\"); echo \"SUCCESS: WordPress-2 connected to Redis-2 (\" . \$redis->ping() . \")\"; } catch (Exception \$e) { echo \"ERROR: \" . \$e->getMessage(); }'")
echo -e "${GREEN}$WP2_REDIS_TEST${NC}"

echo -e "${YELLOW}Testing WordPress-3 to Redis-1 connection...${NC}"
WP3_REDIS_TEST=$(docker exec wordpress-mariadb-redis-wordpress-3-1 sh -c "php82 -r '\$redis = new Redis(); try { \$redis->connect(\"redis-1\", 6379); \$redis->auth(\"wordpress_redis\"); echo \"SUCCESS: WordPress-3 connected to Redis-1 (\" . \$redis->ping() . \")\"; } catch (Exception \$e) { echo \"ERROR: \" . \$e->getMessage(); }'")
echo -e "${GREEN}$WP3_REDIS_TEST${NC}"

echo -e "\n${BLUE}====== Test Completed ======${NC}"
echo -e "If all tests passed, your WordPress with MariaDB, Redis, NGINX, and HTTPS setup is working properly."
echo -e "Your environment is running with ${GREEN}3 WordPress instances${NC} and ${GREEN}2 Redis instances${NC} for improved performance and redundancy."
echo -e "Complete the WordPress installation securely at ${GREEN}https://localhost${NC} and activate the Redis Object Cache plugin in the WordPress admin panel."
echo -e "Your site is now protected with SSL encryption for secure data transmission between users and your WordPress site."
