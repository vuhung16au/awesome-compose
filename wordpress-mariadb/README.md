# WordPress with MariaDB

This example defines one of the basic setups for WordPress with MariaDB as the database. More details on how this works can be found on the official [WordPress image page](https://hub.docker.com/_/wordpress).


Project structure:
```
.
├── compose.yaml
└── README.md
```

[_compose.yaml_](compose.yaml)
```yaml
services:
  db:
    # Switching to MariaDB which supports arm64 architecture and is compatible with WordPress
    image: mariadb:10.9
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
    image: wordpress:6.4-php8.1-apache
    ports:
      - 80:80
    restart: always
    ...
```

When deploying this setup, docker compose maps the WordPress container port 80 to
port 80 of the host as specified in the compose file.

> ℹ️ **_INFO_**  
> For compatibility purpose between `AMD64` and `ARM64` architecture, we use MariaDB as database.  
> MariaDB 10.9 is compatible with both architectures and works well with WordPress as of 17 May 2025.  
> Note: WordPress does not natively support PostgreSQL but is fully compatible with MySQL/MariaDB, which is why MariaDB was chosen as the database solution.

## Deploy with docker compose

```bash
docker compose up -d
```

Example output:

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
d4feb59bab20   wordpress:6.4-php8.1-apache   "docker-entrypoint.s…"   47 seconds ago   Up 46 seconds   0.0.0.0:80->80/tcp   wordpress-mariadb-wordpress-1
0ff2639f74ca   mariadb:10.9                  "docker-entrypoint.s…"   47 seconds ago   Up 46 seconds   3306/tcp             wordpress-mariadb-db-1
```

Navigate to `http://localhost:80` in your web browser to access WordPress.

![Wordpress Installation](wordpress-installation.png)

Stop and remove the containers:

```bash
docker compose down
```

To remove all WordPress data, delete the named volumes by passing the `-v` parameter:

```bash
docker compose down -v
```
