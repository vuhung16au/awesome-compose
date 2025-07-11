## WordPress with MySQL and phpMyAdmin
This example defines a complete local development setup for WordPress with database management capabilities. The setup includes WordPress, MySQL, and phpMyAdmin services. More details on how this works can be found on the official [WordPress image page](https://hub.docker.com/_/wordpress).

---

## Why Are There Two Docker Compose Files?

This project provides **two different Docker Compose files** for demonstration and flexibility:

- **docker-compose.yml**: A full-featured setup including WordPress, MySQL, and phpMyAdmin, with explicit network and volume configuration.
- **compose.yaml**: A minimal, modern Compose file using MariaDB (a MySQL-compatible alternative) and WordPress, with a simpler structure and no phpMyAdmin.

**Reasons for having both files:**
- **Size and complexity comparison:** See the difference between a minimal and a full-featured Compose setup.
- **User choice:** Use either file depending on your needs—minimal stack or full stack with database management UI.

---

## Comparison: `docker-compose.yml` vs `compose.yaml`

| Feature                | docker-compose.yml         | compose.yaml                |
|------------------------|---------------------------|-----------------------------|
| Database               | MySQL                     | MariaDB (MySQL-compatible)  |
| WordPress              | Yes                       | Yes                         |
| phpMyAdmin             | Yes                       | No                          |
| Custom Network         | Yes                       | No (uses default)           |
| Port Mapping           | WordPress: 80, phpMyAdmin: 8080 | WordPress: 80         |
| Compose Syntax         | Classic, more verbose     | Modern, minimal             |
| More Features          | Yes                       | No                          |
| Simpler                | No                        | Yes                         |

- **Use `docker-compose.yml`** if you want a full-featured local development environment with phpMyAdmin and explicit configuration.
- **Use `compose.yaml`** if you want a minimal, modern stack and are comfortable managing the database without phpMyAdmin.

---

Project structure:
```
.
├── docker-compose.yml
├── compose.yaml
└── README.md
```

[_docker-compose.yml_](docker-compose.yml)
```
services:
  # MySQL Database service
  db:
    image: mysql:latest
    restart: always
    volumes:
      - db_data:/var/lib/mysql
    ...
  # WordPress service
  wordpress:
    image: wordpress:latest
    ports:
      - "80:80"
    restart: always
    ...
  # phpMyAdmin service
  phpmyadmin:
    image: phpmyadmin:latest
    ports:
      - "8080:80"
    restart: always
    ...
```

## Services Overview

### WordPress
- Uses the latest stable WordPress image from Docker Hub
- Exposed on port 80 of the host machine
- Connects to the MySQL database using service name 'db'
- Configured with database credentials for local development

### MySQL
- Uses the latest stable MySQL image from Docker Hub
- Serves as the database backend for WordPress
- Configured with simple credentials suitable for local development
- Data persisted through a named volume for durability between container restarts

### phpMyAdmin
- Uses the latest stable phpMyAdmin image from Docker Hub
- Exposed on port 8080 of the host machine
- Connected to the MySQL service using the same credentials as WordPress
- Provides a web interface for easy database management

When deploying this setup, docker compose maps the WordPress container port 80 to
port 80 of the host, and phpMyAdmin port 80 to port 8080 of the host as specified in the compose file.

## How to Start the Services

### Quick Start

To start all services in the background (detached mode):

```bash
docker compose up -d
```

### Alternative: Using the minimal setup

If you prefer the minimal MariaDB setup without phpMyAdmin:

```bash
docker compose -f compose.yaml up -d
```

### Viewing logs during startup

To see the startup process and logs:

```bash
docker compose up
```

### Expected output when starting

```bash
$ docker compose up -d
[+] Creating network "wordpress-mysql_wordpress_network" with the default driver
[+] Creating volume "wordpress-mysql_db_data" with default driver
[+] Creating wordpress-mysql_db_1          ... done
[+] Creating wordpress-mysql_wordpress_1   ... done
[+] Creating wordpress-mysql_phpmyadmin_1  ... done
```

## Expected result

Check containers are running and the port mapping:

```bash
$ docker ps
CONTAINER ID   IMAGE                COMMAND                  CREATED          STATUS          PORTS                                   NAMES
aabbcc123456   phpmyadmin:latest    "/docker-entrypoint.…"   30 seconds ago   Up 29 seconds   0.0.0.0:8080->80/tcp                    wordpress-mysql_phpmyadmin_1
ddeeff789012   wordpress:latest     "docker-entrypoint.s…"   30 seconds ago   Up 29 seconds   0.0.0.0:80->80/tcp                      wordpress-mysql_wordpress_1
112233445566   mysql:latest         "docker-entrypoint.s…"   30 seconds ago   Up 29 seconds   3306/tcp, 33060/tcp                     wordpress-mysql_db_1
```

## Accessing the Services

### Access WordPress

- Navigate to `http://localhost:80` in your web browser to access WordPress.
- Follow the WordPress setup wizard to complete installation.

### Access phpMyAdmin

- Navigate to `http://localhost:8080` in your web browser to access phpMyAdmin.
- Login using the MySQL credentials:
  - Username: wordpress
  - Password: wordpress

![page](output.jpg)

## Managing the Services

### Stop and remove the containers

```bash
docker compose down
```

### Remove all data (including database data)

To remove all WordPress and database data, delete the named volumes by passing the `-v` parameter:

```bash
docker compose down -v
```

## Troubleshooting

If any service fails to start, check the logs using:

```bash
docker compose logs <service_name>
```

Where `<service_name>` is one of: `wordpress`, `db`, or `phpmyadmin`.
