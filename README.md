# Inception
*This project has been created as part of the 42 curriculum by hacharka.*
## Description

**Inception** is a system administration project from the 42 curriculum. Its goal is to build a small infrastructure using Docker and Docker Compose, with each main service running in its own container.

The infrastructure is designed around a WordPress website:

- **Nginx** is the web server and the only public entry point. It receives HTTPS requests and forwards PHP requests to WordPress through PHP-FPM.
- **WordPress** is the content management system (CMS) used to serve and manage the website.
- **MariaDB** stores the WordPress data in a relational database.
- The services communicate through a dedicated Docker network.
- Persistent data is stored outside the containers so that recreating a container does not erase the website or database.

The repository also contains bonus service directories:

- **Adminer** — a web interface for managing the database.
- **FTP** — a file-transfer service for accessing the WordPress files.
- **Redis** — an in-memory data store that can be used as a WordPress object cache.
- **Website** — an additional website service.

The actual services started by Compose, their published ports, and their dependencies are defined in `srcs/docker-compose.yml`.

## Project description

### Architecture

The project follows a multi-container architecture. Each service has its own responsibility and is built from its own Dockerfile where applicable.

```text
                         Host machine
                              |
                         HTTPS :443
                              |
                         [  Nginx  ]
                              |
                       FastCGI :9000
                              |
                         [ WordPress ]
                              |
                        MySQL :3306
                              |
                         [ MariaDB ]

             All application services communicate
                through the Docker network.
```

The expected request flow is:

1. A user opens the website using the configured domain name over HTTPS.
2. Nginx receives the request on port `443`.
3. Nginx serves static files directly when appropriate.
4. When the request requires PHP, Nginx forwards it to the WordPress PHP-FPM service on port `9000`.
5. WordPress connects to MariaDB on port `3306` using the database service name as its hostname.
6. MariaDB reads or writes persistent database data.

Inside a user-defined Docker network, containers can reach each other using their Compose service names. For example, WordPress can use `mariadb:3306` to connect to the database. The service name is resolved by Docker's internal DNS; it is not a public hostname.

### Docker: main design choices

**Docker** packages an application and its dependencies into an image. A container is a running instance of an image. Containers isolate processes and their environments while sharing the host machine's kernel.

This project uses Docker because it makes the infrastructure reproducible and separates services into independent components. Each service can be built, started, stopped, inspected, and replaced independently.

The main design choices are:

- **One service per container:** Nginx, WordPress/PHP-FPM, and MariaDB have separate responsibilities and separate containers.
- **Docker Compose:** the infrastructure is described in one YAML file, making services, networks, volumes, environment configuration, and dependencies easier to manage.
- **A dedicated bridge network:** application containers communicate privately using service names.
- **Persistent storage:** database and WordPress files are stored in persistent storage rather than relying on a container's writable layer.
- **Nginx as the public entry point:** browser traffic reaches the infrastructure through HTTPS on port `443`; backend service ports are used for internal communication.
- **Secrets for sensitive credentials:** passwords are kept in files under `srcs/secrets/` and are intended to be provided to containers as Docker secrets rather than committed as ordinary configuration values.
- **Environment variables for configuration:** non-secret settings and values needed to configure services are defined in `srcs/.env`. The `.env` file must not be committed to the repository.

### Virtual Machines vs Docker

| Virtual Machines | Docker containers |
|---|---|
| Each VM runs its own guest operating system and kernel. | Containers share the host kernel. |
| A hypervisor virtualizes hardware for each VM. | The container runtime isolates processes and resources using Linux kernel features. |
| Usually requires more memory and storage. | Usually lighter and faster to start. |
| Useful when a separate operating system or kernel is required. | Useful for packaging and isolating applications and their dependencies. |
| Provides a stronger OS-level separation boundary in many configurations. | Provides process and resource isolation, but is not the same security boundary as a separate VM. |

In this project, Docker is suitable because the services need separate environments and lifecycles, not separate guest operating systems.

### Secrets vs Environment Variables

| Docker secrets | Environment variables |
|---|---|
| Intended for sensitive values such as passwords and private keys. | Convenient for ordinary configuration such as database names, usernames, and domain names. |
| In Docker Compose, a granted secret is made available to a service as a file, normally under `/run/secrets/`. | Values are injected into the process environment. |
| A service reads the secret from the mounted file. | A service reads the value from its environment. |
| Avoids placing the secret directly in the Compose environment configuration. | Environment values may be exposed through container inspection, process diagnostics, or logs if handled carelessly. |

This project separates sensitive credentials into `srcs/secrets/` and uses `srcs/.env` for configuration. The Compose file must explicitly declare and grant each secret to the services that need it. A secret file should never be copied into a public Git repository.

> **Important:** Docker Compose secrets provided through local file sources are mounted as files inside containers. They should not be confused with an encrypted secrets-management service. Protect the source files with appropriate filesystem permissions and keep them out of Git.

### Docker Network vs Host Network

| Bridge / user-defined Docker network | Host network |
|---|---|
| Containers have network interfaces in an isolated network namespace. | The container shares the host's network namespace. |
| Containers on the same user-defined network can communicate using service names through Docker DNS. | Services use the host's network stack directly. |
| Ports can be published to make selected container ports reachable from the host. | Port publishing is generally unnecessary and is not used in the same way. |
| Provides useful network separation between the containers and the host. | Reduces network isolation and can create port conflicts with host services. |

This project uses a dedicated Docker network so that services such as WordPress and MariaDB can communicate privately. WordPress connects to `mariadb:3306`; it does not use `localhost` for the MariaDB container. Inside a container, `localhost` refers to that same container.

### Docker Volumes vs Bind Mounts

| Docker volumes | Bind mounts |
|---|---|
| Managed by Docker. | Map a specific host filesystem path into a container. |
| Created and managed independently of a particular host directory chosen by the user. | The host path is explicitly selected in the Compose configuration. |
| Convenient for persistent application data without depending on a fixed host path. | Useful when the project needs direct access to files at a known host location. |
| Can be inspected and managed with Docker volume commands. | Files can also be accessed directly from the host. |

Persistent WordPress and MariaDB data must survive container recreation. Check the `volumes` section of `srcs/docker-compose.yml` for the exact storage type and host paths configured in this checkout. The container paths commonly used by these services are:

- WordPress files: `/var/www/html`
- MariaDB data: `/var/lib/mysql`

Do not remove the persistent volumes or host data directories when you want to keep the website and database.

### Repository structure

```text
.
├── Makefile
├── README.md
└── srcs/
    ├── .env                    # Local environment configuration (not committed)
    ├── docker-compose.yml      # Services, networks, volumes and secrets
    ├── secrets/                # Sensitive credential files (not committed)
    │   ├── credentials.txt
    │   ├── db_password.txt
    │   ├── db_root_password.txt
    │   ├── ftp_user_password.txt
    │   ├── wp_admin_password.txt
    │   └── wp_user_password.txt
    └── requirements/
        ├── mariadb/
        │   ├── conf/
        │   ├── tools/
        │   │   └── mariadb_setup.sh
        │   └── Dockerfile
        ├── nginx/
        ├── wordpress/
        │   ├── conf/
        │   ├── tools/
        │   │   └── wp_setup.sh
        │   └── Dockerfile
        └── bonus/
            ├── adminer/
            ├── ftp/
            ├── redis/
            └── website/
```

The `conf/` directories contain service configuration, `tools/` contains setup scripts, and each service's `Dockerfile` defines how its image is built. The bonus directories contain the additional service configurations and related files.

## Instructions

### Prerequisites

Before starting, make sure you have:

- A Linux environment or a compatible virtual machine.
- Docker Engine installed and running.
- Docker Compose v2 (`docker compose`).
- `make`.
- Permission to run Docker commands, either directly or through `sudo`.

### Configuration

1. Clone the repository:

   ```bash
   git clone <repository-url>
   cd Inception_42
   ```

2. Create `srcs/.env` using the variables expected by `srcs/docker-compose.yml` and the service configuration files. Typical values include:

   ```dotenv
   DOMAIN_NAME=hacharka.42.fr
   MYSQL_DATABASE=wordpress
   MYSQL_USER=wp_user
   MYSQL_PASSWORD=change_this_password
   MYSQL_ROOT_PASSWORD=change_this_root_password
   ```

   Use the exact variable names referenced by your Compose file and scripts. Do not use the example passwords in a real environment.

3. Create the secret files expected by the Compose file under `srcs/secrets/`. The repository structure currently includes:

   - `credentials.txt`
   - `db_password.txt`
   - `db_root_password.txt`
   - `ftp_user_password.txt`
   - `wp_admin_password.txt`
   - `wp_user_password.txt`

   Put the appropriate credential in each file, following the format read by the corresponding setup script. Do not add real credentials to Git.

4. Configure the domain on the host machine so that it resolves to the machine running the project. For a local Linux setup, add an entry to `/etc/hosts` (replace the domain if your `.env` uses another value):

   ```text
   127.0.0.1  hacharka.42.fr
   ```

   If Docker runs inside a VM or remote environment, use the appropriate reachable IP address instead of `127.0.0.1`.

### Build and run

From the repository root, build and start the Compose infrastructure:

```bash
docker compose --env-file srcs/.env -f srcs/docker-compose.yml up -d --build
```

Check the status of the services:

```bash
docker compose --env-file srcs/.env -f srcs/docker-compose.yml ps
```

Follow the logs:

```bash
docker compose --env-file srcs/.env -f srcs/docker-compose.yml logs -f
```

Open the website in a browser:

```text
https://hacharka.42.fr
```

The project uses HTTPS. If the Nginx certificate is self-signed, the browser may display a security warning during local testing.

To stop the services without deleting persistent data:

```bash
docker compose --env-file srcs/.env -f srcs/docker-compose.yml down
```

To rebuild after changing a Dockerfile or service configuration:

```bash
docker compose --env-file srcs/.env -f srcs/docker-compose.yml up -d --build
```

To inspect a specific service's logs:

```bash
docker compose --env-file srcs/.env -f srcs/docker-compose.yml logs -f nginx
docker compose --env-file srcs/.env -f srcs/docker-compose.yml logs -f wordpress
docker compose --env-file srcs/.env -f srcs/docker-compose.yml logs -f mariadb
```

> **Data warning:** `docker compose down` normally keeps named volumes. Avoid `docker compose down -v` and avoid deleting the host data directories unless you intentionally want to erase persistent application/database data. Review the Makefile before using cleanup targets, because some cleanup commands may remove stored data.

### Useful commands

```bash
# List running containers
docker ps

# List images
docker images

# List Docker networks
docker network ls

# List Docker volumes
docker volume ls

# Inspect a container
docker inspect <container_name>

# Open a shell in a running container
docker exec -it <container_name> sh
```

## Resources

### Official documentation

- [42 Inception subject](https://cdn.intra.42.fr/pdf/pdf/ project-inception.pdf) — consult the subject provided by your 42 campus for the authoritative requirements.
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