# Inception

*This project has been created as part of the 42 curriculum by hacharka.*

## Description

**Inception** is a system administration project from the 42 curriculum. Its goal is to build a small infrastructure using Docker and Docker Compose, with each service running in its own container.

The infrastructure hosts a WordPress website and includes the following services:

- **Nginx:** Web server and the only public entry point. Handles HTTPS requests and forwards PHP requests to WordPress.
- **WordPress:** Content management system (CMS) used to create and manage the website.
- **MariaDB:** Relational database used to store WordPress data.

The project also includes bonus services:

- **Redis:** In-memory cache used to improve WordPress performance.
- **FTP:** File-transfer service for accessing WordPress files.
- **Adminer:** Web interface for managing the database.
- **Website:** An additional website service.

Services communicate through a dedicated Docker network, and persistent data is stored outside the containers to survive container recreation.

The services, networks, volumes, and dependencies are defined in `srcs/docker-compose.yml`.

## Architecture

The project follows a multi-container architecture, where each service has its own responsibility.

### Infrastructure diagram

```text
                  Host Machine
                       |
                  HTTPS :443
                       |
                    Nginx
                       |
                 FastCGI :9000
                       |
                   WordPress
                       |
                  MySQL :3306
                       |
                    MariaDB

          All services communicate through
             a dedicated Docker network.
```

### Request flow

1. A user accesses the website through its domain name using HTTPS.
2. Nginx receives the request on port 443.
3. Nginx serves static files or forwards PHP requests to WordPress through PHP-FPM on port 9000.
4. WordPress communicates with MariaDB on port 3306.
5. MariaDB reads or writes data in persistent storage.

Containers communicate using their Compose service names. For example, WordPress connects to MariaDB using `mariadb:3306`. Docker's internal DNS resolves the service name.

## Technical Concepts

### Docker and Virtual Machines

Docker allows applications and their dependencies to run in isolated containers.

| Virtual Machines | Docker Containers |
|---|---|
| Run a separate guest operating system. | Share the host operating system kernel. |
| Require a hypervisor. | Use container runtimes and Linux kernel features. |
| Generally consume more resources. | Generally lightweight and faster to start. |
| Provide separate operating system environments. | Provide process and resource isolation. |

Docker is suitable for this project because each service needs an independent environment without requiring a separate operating system.

### Docker Network: Bridge vs Host

Docker provides different network modes that determine how containers communicate with other containers and the host machine.

| Bridge Network | Host Network |
|---|---|
| Creates an isolated network for containers. | Shares the host machine's network namespace. |
| Containers have their own network interfaces and IP addresses. | Containers use the host's network interfaces and IP address. |
| Containers on the same user-defined network can communicate using service names through Docker DNS. | Containers communicate through the host's network stack. |
| Port mapping (`-p`) is used to expose container ports to the host. | Port mapping is unnecessary and generally ignored. |
| Provides network isolation between containers and the host. | Removes network namespace isolation between the container and host. |

**Network configuration in this project:**

This project uses a dedicated user-defined bridge network to allow containers to communicate privately.

For example:
- WordPress connects to MariaDB using `mariadb:3306`.
- Nginx forwards PHP requests to WordPress using `wordpress:9000`.
- Docker DNS resolves service names to their corresponding container IP addresses.

Inside a container, `localhost` refers to that same container, not another container or the host machine.

### Docker Volumes and Bind Mounts

Both mechanisms allow data to persist outside a container.

| Docker Volumes | Bind Mounts |
|---|---|
| Managed by Docker. | Host directory selected by the user. |
| Stored in Docker's storage area. | Stored at a specific host path. |
| Managed using Docker commands. | Files can be accessed directly from the host. |

This project uses **Bind Mounts** for persistent WordPress and MariaDB data:

- WordPress: `/home/hacharka/data/wordpress`
- MariaDB: `/home/hacharka/data/mariadb`

These directories are mounted inside their respective containers.

### Environment Variables and Secrets

The project separates configuration values from sensitive credentials.

- **Environment variables:** Used for configuration such as domain names, database names, and usernames.
- **Secrets:** Used for sensitive information such as passwords.

Configuration is stored in `srcs/.env`, while sensitive credentials are stored in `srcs/secrets/`.

Secret files and environment files containing credentials must not be committed to Git.

## Repository Structure

```text
.
├── srcs/
│   ├── requirements/
│   │   ├── bonus/
│   │   │   ├── adminer/
│   │   │   ├── ftp/
│   │   │   ├── redis/
│   │   │   └── website/
│   │   │
│   │   ├── mariadb/
│   │   │   ├── conf/
│   │   │   ├── tools/
│   │   │   │   └── mariadb_setup.sh
│   │   │   ├── .dockerignore
│   │   │   └── Dockerfile
│   │   │
│   │   ├── nginx/
│   │   │   ├── conf/
│   │   │   │   └── nginx.conf
│   │   │   ├── .dockerignore
│   │   │   └── Dockerfile
│   │   │
│   │   └── wordpress/
│   │       ├── conf/
│   │       ├── tools/
│   │       │   └── wp_setup.sh
│   │       ├── .dockerignore
│   │       └── Dockerfile
│   │
│   ├── secrets/
│   │   ├── credentials.txt
│   │   ├── db_password.txt
│   │   ├── db_root_password.txt
│   │   ├── ftp_user_password.txt
│   │   ├── wp_admin_password.txt
│   │   └── wp_user_password.txt
│   │
│   ├── .env
│   └── docker-compose.yml
│
├── .gitignore
├── DEV_DOC.md
├── Makefile
├── README.md
└── USER_DOC.md
```

Each service directory contains its Dockerfile and the configuration or scripts required to build and run the service.

## Instructions

### Prerequisites

Make sure you have:

- Linux environment or a compatible virtual machine.
- Docker Engine installed and running.
- Docker Compose v2.
- Make.
- Sufficient permissions to execute Docker commands.

### Configuration

**1. Clone the repository**

```bash
git clone <repository-url>
cd Inception_42
```

**2. Create the environment file**

Create `srcs/.env` and define the variables required by your Compose file and service configuration.

Example:

```env
DOMAIN_NAME=hacharka.42.fr

MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser

WP_TITLE=Inception
WP_ADMIN_USER=hacharka_boss
WP_ADMIN_EMAIL=you@example.com
WP_USER=editor
WP_USER_EMAIL=editor@example.com

FTP_USER=ftpuser
```

Use the exact variable names expected by your configuration files.

**3. Configure Docker secrets**

Create the required credential files inside `srcs/secrets/` and provide the appropriate passwords.

Do not commit real credentials to Git.

**4. Configure the domain**

Add the following entry to `/etc/hosts` on the host machine:

```text
127.0.0.1 hacharka.42.fr
```

If Docker runs inside a virtual machine or remote environment, use the appropriate reachable IP address instead.

## Usage

All infrastructure operations are managed through the Makefile.

### Build and Start

From the repository root, run:

```bash
make
```

This builds the Docker images, creates the required data directories under `/home/hacharka/data`, and starts all services in detached mode.

You can also use:

```bash
make up
```

### Build Docker Images

To build the images without starting the containers:

```bash
make build
```

### Check Services

To check the status of the running containers:

```bash
docker compose -f srcs/docker-compose.yml ps
```

### Follow Logs

To follow the logs of all services:

```bash
docker compose -f srcs/docker-compose.yml logs -f
```

To inspect a specific service:

```bash
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
```

### Access the Website

Open your browser and navigate to:

```text
https://hacharka.42.fr
```

The project uses HTTPS with a self-signed SSL certificate. Your browser may display a security warning during local testing.

### Stop and Clean the Infrastructure

**Stop containers and remove Compose resources:**

```bash
make down
```

This also removes named Docker volumes because the Makefile uses `docker compose down -v`. However, your bind-mounted data directories remain intact.

**Remove unused Docker resources:**

```bash
make clean
```

This runs `make down` followed by `docker system prune -a --force`.

**Complete cleanup:**

```bash
make fclean
```

This removes unused Docker resources, prunes unused volumes, and deletes the WordPress and MariaDB data directories under `/home/hacharka/data`.

**Rebuild the entire infrastructure:**

```bash
make re
```

This performs a complete cleanup followed by a fresh build and startup.

**Warning:** `make fclean` permanently deletes your WordPress files and MariaDB database. Use it only when you intentionally want to reset the project.

## Stopping and Cleaning

The Makefile provides several commands to manage the infrastructure.

| Command | Description |
|---|---|
| `make` | Build and start the infrastructure. |
| `make up` | Build and start the containers. |
| `make build` | Build Docker images without starting containers. |
| `make down` | Stop containers and remove Compose resources and named volumes. |
| `make clean` | Run `make down` and remove unused Docker images and resources. |
| `make fclean` | Complete cleanup, including persistent host data directories. |
| `make re` | Perform a complete cleanup followed by a fresh build and startup. |

**Important data warning:**

This project uses bind mounts for WordPress and MariaDB data.

- `make down` removes containers, networks, and named Docker volumes, but preserves the bind-mounted host directories.
- `make clean` additionally runs Docker system prune.
- `make fclean` deletes the WordPress and MariaDB host data directories under `/home/hacharka/data`.

**Warning:** `make fclean` permanently deletes your website and database data. Use it only when you intentionally want a fresh installation.

## Useful Docker Commands

```bash
# List running containers
docker ps

# List Docker images
docker images

# List Docker networks
docker network ls

# List Docker volumes
docker volume ls

# Inspect a container
docker inspect <container_name>

# Open a shell inside a running container
docker exec -it <container_name> sh
```

## Documentation

For more information about the project:

- `USER_DOC.md`: Instructions for using and managing the infrastructure.
- `DEV_DOC.md`: Technical information about the implementation and development choices.

## Resources

### Official documentation

- [Docker documentation](https://docs.docker.com/)
- [Docker Compose documentation](https://docs.docker.com/compose/)
- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/)
- [Docker volumes](https://docs.docker.com/engine/storage/volumes/)
- [Docker bind mounts](https://docs.docker.com/engine/storage/bind-mounts/)
- [Docker networking](https://docs.docker.com/engine/network/)
- [Docker Compose secrets](https://docs.docker.com/compose/how-tos/use-secrets/)
- [Nginx documentation](https://nginx.org/en/docs/)
- [WordPress documentation](https://wordpress.org/documentation/)
- [MariaDB documentation](https://mariadb.com/kb/en/documentation/)
- [PHP-FPM documentation](https://www.php.net/manual/en/install.fpm.php)
- [Redis documentation](https://redis.io/docs/)
- [Adminer documentation](https://www.adminer.org/)
- [FileZilla documentation](https://filezilla-project.org/)

### AI usage

AI tools were used as learning and support tools during the project for:

- Explaining Docker concepts such as images, containers, layers, volumes, networks, namespaces, and port mapping.
- Understanding the roles and interactions of Nginx, WordPress, PHP-FPM, MariaDB, and the bonus services.
- Helping investigate configuration and runtime errors in Dockerfiles, Docker Compose, shell scripts, and service networking.
- Reviewing command usage and helping structure troubleshooting steps.


---

*Created for the 42 Inception project.*