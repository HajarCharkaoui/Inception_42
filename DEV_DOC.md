# DEV_DOC — Developer Documentation

This document explains how a developer can set up, build, run, and maintain the **Inception** project from scratch, and where its data lives.

> **Note:** paths, service names, and variable names below are the defaults of this project. Adjust them if your `srcs/` files differ.

---

## 1. Project overview

The project is a multi-container infrastructure orchestrated with **Docker Compose**, running inside a Virtual Machine. Every service has its own `Dockerfile` (no pre-built images from Docker Hub except the base OS image).

```
.
├── Makefile
├── secrets/                  # passwords (not committed to Git)
└── srcs/
    ├── docker-compose.yml
    ├── .env                  # non-secret configuration (not committed to Git)
    └── requirements/
        ├── nginx/            # Dockerfile + conf + TLS setup
        ├── wordpress/        # Dockerfile + php-fpm conf + setup script
        ├── mariadb/          # Dockerfile + conf + init script
        └── bonus/
            ├── redis/
            ├── ftp/
            ├── adminer/
            └── website/      # static site (resume), listens on port 3000
```

### Services and how they talk to each other

| Service | Container role | Internal port | Exposed to host |
|---------|----------------|---------------|-----------------|
| `nginx` | HTTPS reverse proxy (TLS 1.2 / 1.3 only) | 443 | **443** |
| `wordpress` | WordPress + PHP-FPM | 9000 | no |
| `mariadb` | Database | 3306 | no |
| `redis` | WordPress object cache | 6379 | no |
| `ftp` | FTP server on the WordPress files | 21 (+ passive range) | 21 (+ passive range) |
| `adminer` | Database web UI | 8080 | 8080 |
| `website` | Static resume site | 3000 | no (reached via NGINX at `/resume/`) |

All containers are attached to one custom **bridge network**, so they reach each other by service name (e.g. NGINX uses `fastcgi_pass wordpress:9000;` and `proxy_pass http://website:3000/;`).

---

## 2. Setting up the environment from scratch

### 2.1 Prerequisites

Install on your VM (Debian/Ubuntu example):

```bash
sudo apt update
sudo apt install -y make git sudo
# Docker Engine + Compose plugin: follow https://docs.docker.com/engine/install/
```

Check the installation:

```bash
docker --version
docker compose version
make --version
```

Add your user to the `docker` group so you can run Docker without `sudo`, then log out and back in:

```bash
sudo usermod -aG docker $USER
```

### 2.2 Domain name

The site is served at `hacharka.42.fr`. Point it to your local machine:

```bash
echo "127.0.0.1   hacharka.42.fr" | sudo tee -a /etc/hosts
```

### 2.3 Configuration file: `srcs/.env`

Create `srcs/.env` with the non-secret settings. Example (names may differ in your project):

```env
DOMAIN_NAME=hacharka.42.fr

# MariaDB
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser

# WordPress
WP_TITLE=Inception
WP_ADMIN_USER=hacharka_boss        # must NOT contain "admin" / "administrator"
WP_ADMIN_EMAIL=you@example.com
WP_USER=editor
WP_USER_EMAIL=editor@example.com

# FTP
FTP_USER=ftpuser
```

### 2.4 Secrets

Passwords must **never** be written in a `Dockerfile` or committed to Git. Store them in the `secrets/` folder (one file per secret) or in `.env`, depending on how your compose file loads them:

| Secret | Used by |
|--------|---------|
| Database root password | MariaDB |
| Database user password | MariaDB, WordPress |
| WordPress admin password | WordPress setup script |
| WordPress second user password | WordPress setup script |
| FTP password | FTP server |

Example:

```bash
mkdir -p secrets
echo "a-strong-root-password"  > secrets/db_root_password.txt
echo "a-strong-user-password"  > secrets/db_password.txt
echo "a-strong-wp-admin-pass"  > secrets/wp_admin_password.txt
echo "a-strong-wp-user-pass"   > secrets/wp_user_password.txt
echo "a-strong-ftp-password"   > secrets/ftp_password.txt
chmod 600 secrets/*
```

Make sure `.gitignore` contains:

```
srcs/.env
secrets/
```

### 2.5 Host data folders

The Makefile creates them automatically, but they can be created manually:

```bash
mkdir -p /home/hacharka/data/wordpress /home/hacharka/data/mariadb
```

---

## 3. Building and launching the project

### 3.1 Makefile targets

| Target | Command run | Purpose |
|--------|-------------|---------|
| `make` / `make all` | → `make up` | Default: build and start everything. |
| `make up` | creates data folders, then `docker compose -f srcs/docker-compose.yml up -d` | Starts all containers in the background (builds first). |
| `make build` | `docker compose -f srcs/docker-compose.yml build` | Builds all images without starting. |
| `make down` | `docker compose -f srcs/docker-compose.yml down -v` | Stops and removes containers, network, and compose volumes. |
| `make clean` | `down` + `docker system prune -a --force` | Also removes all unused images, containers, and networks. |
| `make fclean` | `clean` + deletes `/home/hacharka/data/*` content + `docker volume prune -f` | Full reset, **erases all persistent data**. |
| `make re` | `fclean` + `all` | Rebuild everything from zero. |

### 3.2 First launch

```bash
git clone <your-repo-url> inception
cd inception
# create srcs/.env and secrets/ (see section 2)
make
```

Then open `https://hacharka.42.fr` (accept the self-signed certificate warning).

### 3.3 Using Docker Compose directly

You can skip the Makefile when developing. Define a shortcut:

```bash
alias dc='docker compose -f srcs/docker-compose.yml'
```

```bash
dc build                       # build all images
dc build nginx                 # rebuild one image
dc up -d                       # start in background
dc up -d --build wordpress     # rebuild and restart a single service
dc stop                        # stop containers (keep them)
dc start                       # start stopped containers
dc restart nginx               # restart one service
dc down                        # stop and remove containers + network
```

---

## 4. Managing containers and volumes

### 4.1 Containers

```bash
dc ps                          # status of the stack
docker ps -a                   # all containers on the machine
dc logs -f <service>           # follow the logs of a service
docker exec -it <container> sh # open a shell inside a container (use bash if installed)
docker stats                   # live CPU / memory usage
docker inspect <container>     # full configuration of a container
```

Useful checks:

```bash
docker exec -it mariadb mariadb -u <db_user> -p      # open a SQL session
docker exec -it redis redis-cli ping                 # expect PONG
docker exec -it nginx nginx -t                       # test NGINX config syntax
docker exec -it nginx nginx -s reload                # reload NGINX config
docker exec -it wordpress ls /var/www/html           # list WordPress files
```

### 4.2 Images and network

```bash
docker images                  # list images
docker image rm <image>        # remove an image
docker network ls              # list networks
docker network inspect <name>  # see which containers are attached
docker system df               # disk usage of Docker
```

### 4.3 Volumes

```bash
docker volume ls                       # list volumes
docker volume inspect <volume_name>    # see where the data is stored
docker volume rm <volume_name>         # remove a volume
docker volume prune -f                 # remove all unused volumes
```

> ⚠️ `make down` uses `-v`, which removes **Docker-managed** volumes. If your volumes are bind-mounted to `/home/hacharka/data/...` (see section 5), the files on the host are **not** deleted by `down`; only `make fclean` deletes them.

### 4.4 Common developer workflows

| Goal | Steps |
|------|-------|
| Change the NGINX config | Edit the conf file → `dc up -d --build nginx` (or `docker exec nginx nginx -s reload` if the file is mounted). |
| Change a WordPress setup script | Edit it → `make fclean && make` (the script usually runs only on first start). |
| Change a password | Edit `secrets/` or `.env` → `make fclean && make`. |
| Start with a clean database | `make down`, then `sudo rm -rf /home/hacharka/data/mariadb/*`, then `make`. |
| A container keeps restarting | `dc logs <service>` to read the error, fix, then `dc up -d --build <service>`. |

---

## 5. Where data is stored and how it persists

### 5.1 Persistent data

| Data | Container path | Host path |
|------|----------------|-----------|
| WordPress files (core, themes, plugins, uploads) | `/var/www/html` | `/home/hacharka/data/wordpress` |
| MariaDB database files | `/var/lib/mysql` | `/home/hacharka/data/mariadb` |

Both are **Docker named volumes configured to store their data on the host** (bind to `/home/hacharka/data/...`), as required by the subject. They are shared as follows:

- `wordpress` volume → mounted in **WordPress**, **NGINX** (to serve static files), and **FTP** (to upload files).
- `mariadb` volume → mounted in **MariaDB** only.

### 5.2 What survives what

| Operation | Containers | Images | Data in `/home/hacharka/data` |
|-----------|------------|--------|-------------------------------|
| `make down` / `dc down` | removed | kept | **kept** |
| container crash / restart | recreated | kept | **kept** |
| VM reboot | stopped | kept | **kept** (run `make` again) |
| `make clean` | removed | removed | **kept** |
| `make fclean` / `make re` | removed | removed | **deleted** |

### 5.3 Not persistent

- Anything written inside a container outside the mounted paths is lost when the container is removed.
- Redis is used as a cache only; its content is rebuilt automatically and is not required to persist.
- The static `website` content comes from its image / source folder and is rebuilt with the image.

### 5.4 Backing up data

```bash
sudo tar czf wordpress_backup.tar.gz -C /home/hacharka/data wordpress
sudo tar czf mariadb_backup.tar.gz   -C /home/hacharka/data mariadb
# or a clean SQL dump:
docker exec mariadb mariadb-dump -u root -p<root_password> <db_name> > backup.sql
```

---

## 6. Good practices checklist

- No password in any `Dockerfile` or committed file.
- `.env` and `secrets/` are listed in `.gitignore`.
- Containers restart automatically (`restart: always` / `unless-stopped` in the compose file).
- Every service runs a **foreground main process** (no `tail -f`, `sleep infinity`, or `while true` hacks).
- Only port **443** (plus the bonus ports) is exposed; MariaDB and PHP-FPM stay internal.
- Images are built from the penultimate stable Alpine/Debian version, with one `Dockerfile` per service.