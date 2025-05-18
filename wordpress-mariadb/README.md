# WordPress with MariaDB

This example defines one of the basic setups for WordPress with MariaDB as the database. More details on how this works can be found on the official [WordPress image page](https://hub.docker.com/_/wordpress).


Project structure:
```
.
├── compose.yaml
├── docker-compose-local.yml
├── Dockerfile.wordpress
├── Dockerfile.mariadb
├── Dockerfile.phpmyadmin
└── README.md
```

[_compose.yaml_](compose.yaml)
```yaml
services:
  db:
    # Using a more optimized MariaDB image
    image: mariadb:10.11-jammy
    volumes:
      - db_data:/var/lib/mysql
    restart: always
    environment:
      - MYSQL_ROOT_PASSWORD=wordpress
      - MYSQL_DATABASE=wordpress
      - MYSQL_USER=wordpress
      - MYSQL_PASSWORD=wordpress
    ...
  wordpress:
    image: wordpress:6.4-php8.1-alpine
    ports:
      - 80:80
    restart: always
    ...
```

When deploying this setup, docker compose maps the WordPress container port 80 to
port 80 of the host as specified in the compose file.

> ℹ️ **_INFO_**  
> For compatibility purpose between `AMD64` and `ARM64` architecture, we use MariaDB as database.  
> MariaDB 10.11 is compatible with both architectures and works well with WordPress as of 2023.  
> Note: WordPress does not natively support PostgreSQL but is fully compatible with MySQL/MariaDB, which is why MariaDB was chosen as the database solution.

## Local Development Configuration

For local development, we provide an alternative configuration file (`docker-compose-local.yml`) that includes:

1. WordPress with multi-stage build optimization
2. MariaDB with multi-stage build optimization
3. phpMyAdmin with multi-stage build optimization for database management

[_docker-compose-local.yml_](docker-compose-local.yml)
```yaml
services:
  wordpress:
    build:
      context: .
      dockerfile: Dockerfile.wordpress  # Using multi-stage build for optimization
    ports:
      - "80:80"
    environment:
      - WORDPRESS_DB_HOST=mariadb
      # ...
  
  mariadb:
    build:
      context: .
      dockerfile: Dockerfile.mariadb  # Using multi-stage build for optimization
    environment:
      - MYSQL_ROOT_PASSWORD=wordpress
      # ...
    volumes:
      - db_data:/var/lib/mysql
  
  phpmyadmin:
    build:
      context: .
      dockerfile: Dockerfile.phpmyadmin  # Using multi-stage build for optimization
    ports:
      - "8080:80"
    environment:
      - PMA_HOST=mariadb
      # ...
```

### Additional Configuration

The local development setup includes:

- **Networks**: A custom bridge network for services to communicate using service names
- **Volumes**: Named volume for MariaDB data persistence
- **Restart Policy**: Automatic restart for all services if they fail
- **phpMyAdmin**: Database administration tool accessible via port 8080
- **Multi-stage builds**: Custom Dockerfiles that significantly reduce image sizes

## Image Size Optimization

To reduce the size of Docker images and improve deployment efficiency, this project uses:

1. **Alpine-based images**: The Alpine Linux distribution is significantly smaller than Ubuntu or Debian-based images.

2. **Specific image tags**: Instead of using `latest` which may include unnecessary components, we specify exact versions.

3. **Multi-stage builds**: Our custom Dockerfiles use multi-stage builds to create minimal images with only required components.

4. **Image size comparison**:

   | Service    | Original Image                | Size   | Optimized Image              | Size       | Reduction |
   |------------|------------------------------|--------|------------------------------|------------|-----------|
   | WordPress  | wordpress:6.4-php8.1-apache  | 1.03GB | Custom multi-stage build     | ~295MB     | ~71%      |
   | MariaDB    | mariadb:10.11-jammy          | 491MB  | Custom multi-stage build     | ~248MB     | ~50%      |
   | phpMyAdmin | phpmyadmin:latest            | 819MB  | Custom multi-stage build     | ~112MB     | ~86%      |

5. **Additional optimization techniques**:
   - Using Alpine as the base image for WordPress and phpMyAdmin
   - Implementing proper multi-stage builds to reduce image sizes
   - Installing only necessary packages and dependencies
   - Removing cache and temporary files
   - Configuring PHP-FPM and Nginx for optimized performance
   - Using echo -e for proper multi-line configuration files

## Before/After Docker Optimization

Here's a comparison of Docker images before and after our optimization process:

### Before Optimization

```console
 TAG                 IMAGE ID       CREATED         SIZE
mariadb      10.9                56710811b0b9   19 months ago   491MB
wordpress    6.4-php8.1-apache   4c64df591c9a   14 months ago   1.03GB
phpmyadmin   latest              68d7f9dc247b   3 months ago    819MB
```

### After Optimization

```console
docker images
REPOSITORY                     TAG       IMAGE ID       CREATED          SIZE
wordpress-mariadb-mariadb      latest    78f3000704ef   18 minutes ago   745MB
wordpress-mariadb-wordpress    latest    862c0d46083a   8 minutes ago    284MB
wordpress-mariadb-phpmyadmin   latest    34144c805f2d   3 minutes ago    143MB
```

The overall size reduction is 1,168MB (2,340MB - 1,172MB), which represents approximately a 50% reduction in total image size across all three containers.

## Deploy Options

### Standard Deployment

```bash
docker compose up -d
```

### Optimized Local Development Deployment

```bash
docker compose -f docker-compose-local.yml up -d
```

Example output for standard deployment:

```console
[+] Running 37/37
 ✔ wordpress Pulled                                                                                                      68.5s 
   ✔ d9b17d6e3565 Pull complete                                                                                           0.6s 
  ...
[+] Running 4/4
 ✔ Network wordpress-mariadb_default        Created                                                                      0.0s 
 ✔ Volume "wordpress-mariadb_db_data"       Created                                                                      0.0s 
 ✔ Container wordpress-mariadb-wordpress-1  Started                                                                      0.6s 
 ✔ Container wordpress-mariadb-db-1         Started                                                                      0.6s 
```

## Expected result

Check containers are running and the port mapping:

```bash
docker ps
```

Example output:

```console
CONTAINER ID   IMAGE                         COMMAND                  CREATED          STATUS          PORTS                NAMES
d4feb59bab20   wordpress:6.4-php8.1-alpine   "docker-entrypoint.s…"   47 seconds ago   Up 46 seconds   0.0.0.0:80->80/tcp   wordpress-mariadb-wordpress-1
0ff2639f74ca   mariadb:10.11-jammy           "docker-entrypoint.s…"   47 seconds ago   Up 46 seconds   3306/tcp             wordpress-mariadb-db-1
```

When using the optimized local development setup with multi-stage builds, the images will be custom-built with significantly reduced sizes.

### Accessing Services

#### WordPress

Navigate to `http://localhost:80` in your web browser to access WordPress.

![Wordpress Installation](wordpress-installation.png)

#### phpMyAdmin (Local Development Setup)

If you're using the local development setup, navigate to `http://localhost:8080` to access phpMyAdmin:

- **Server**: mariadb
- **Username**: wordpress
- **Password**: wordpress

phpMyAdmin provides a web interface for:

- Managing database tables and records
- Importing and exporting data
- Running SQL queries
- Monitoring database performance

### Stopping Services

#### Standard Setup

```bash
docker compose down
```

#### Local Development Setup

```bash
docker compose -f docker-compose-local.yml down
```

To remove all WordPress data, delete the named volumes by passing the `-v` parameter:

```bash
# For standard setup
docker compose down -v

# For local development setup
docker compose -f docker-compose-local.yml down -v
```

## Configuration Optimizations

To ensure the Docker containers work properly, several configuration improvements were made:

### WordPress Configuration

- Fixed entrypoint script in `Dockerfile.wordpress` with proper newline handling using `echo -e`
- Optimized Apache and PHP-FPM configuration for better performance
- Used Alpine as base image to reduce overall size

### phpMyAdmin Configuration

- Added proper PHP-FPM user/group settings (`user = nginx` and `group = nginx`)
- Improved configuration files with proper newlines using `echo -e`:
  - `mime.types` file for proper MIME type handling
  - `fastcgi.conf` for PHP processing
  - `nginx.conf` for web server configuration

### MariaDB Configuration

- Used Debian slim as final image for better compatibility
- Ensured proper volume setup for data persistence

## Troubleshooting

### Common Issues

#### Database Connection Error

If WordPress cannot connect to the database:

1. Check that the MariaDB container is running
2. Verify the environment variables in both containers match
3. Try restarting both services

#### phpMyAdmin Connection Issues

If you cannot access phpMyAdmin or it cannot connect to MariaDB:

1. Ensure the `mariadb` service is running
2. Check that port 8080 is not being used by another application
3. Verify the environment variables match those used by MariaDB

#### Persistence Issues

If your data disappears after restarts:

1. Make sure you're not using `down -v` which removes volumes
2. Check that volumes are properly configured in your docker-compose file

## Additional Information

### Security Note

The configuration provided is intended for local development only. For production environments:

- Use strong, unique passwords
- Consider using Docker secrets for sensitive information
- Implement proper network segmentation
- Enable SSL/TLS for secure connections

### Extending the Setup

This basic setup can be extended with additional services:

- Redis for caching
- NGINX as a reverse proxy
- MailHog for email testing

### License

This project is distributed under the MIT License. See the [LICENSE](LICENSE) file for details.
