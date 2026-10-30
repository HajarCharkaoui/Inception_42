# USER_DOC — User & Administrator Guide

This document explains, in simple terms, how to use and operate the **Inception** stack: what it provides, how to start and stop it, how to reach the website and admin panel, where credentials live, and how to check that everything works.

> **Note:** values such as ports and domain names are the defaults of this project. If you changed them in `srcs/.env` or `srcs/docker-compose.yml`, use your own values.

---

## 1. What services are provided?

The stack runs several Docker containers, each with one job.

### Mandatory services

| Service | Role |
|---------|------|
| **NGINX** | The only public entry point for the website. Serves everything over **HTTPS (port 443)** using TLS 1.2 / 1.3. It forwards PHP requests to WordPress and `/resume/` to the static website. |
| **WordPress + PHP-FPM** | The website itself and its administration panel (`/wp-admin`). |
| **MariaDB** | The database where WordPress stores its pages, users, and settings. |

### Bonus services

| Service | Role |
|---------|------|
| **Redis** | A cache for WordPress. It makes pages load faster by reducing database queries. |
| **FTP server** | Lets you upload and download the WordPress files, either with a graphical FTP client (e.g. FileZilla) or with the ftp command in a terminal. |
| **Adminer** | A web page to browse and manage the MariaDB database. |
| **Static website** | A small extra website (resume), independent from WordPress. It is reached through NGINX at `/resume/`, so it is also protected by HTTPS. |

### Data persistence

Your data is stored on the host machine and survives container restarts:

- WordPress files: `/home/hacharka/data/wordpress`
- Database files: `/home/hacharka/data/mariadb`

---

## 2. Starting and stopping the project

All commands are run from the **root of the project** (where the `Makefile` is).

| Action | Command | What it does |
|--------|---------|--------------|
| **Start** | `make` (or `make up`) | Builds the images, creates the data folders, and starts all containers in the background. |
| **Stop** | `make down` | Stops and removes the containers and the compose network. Your data in `/home/hacharka/data` is kept. |
| **Rebuild images only** | `make build` | Builds the Docker images without starting them. |
| **Clean images** | `make clean` | Stops the stack, then removes all unused Docker images, containers, and networks. |
| **Full reset** | `make fclean` | Same as `clean`, **and deletes all WordPress and database data**. ⚠️ This cannot be undone. |
| **Reset and restart** | `make re` | Full reset followed by a fresh start. ⚠️ Deletes all data. |

> ⚠️ Use `make fclean` and `make re` only if you really want to start from scratch.

The first start can take a few minutes because the images must be built.

---

## 3. Accessing the website and the administration panel

### Prerequisite: domain name

The project uses the domain `hacharka.42.fr`. Make sure it points to your local machine by adding this line to `/etc/hosts`:

```
127.0.0.1   hacharka.42.fr
```

### Addresses

| What | Address |
|------|---------|
| **WordPress website** | `https://hacharka.42.fr` |
| **WordPress admin panel** | `https://hacharka.42.fr/wp-admin` |
| **Adminer (database)** | `http://hacharka.42.fr:8080` |
| **Static website (resume)** | `https://hacharka.42.fr/resume/` |
| **FTP server** | host `hacharka.42.fr`, port `21` |

> The browser will show a **security warning** because the TLS certificate is self-signed. This is expected: choose "Advanced" → "Proceed anyway".
>
> Plain HTTP on port 80 is not served for WordPress; only HTTPS (443) is available.

### Logging in

- **WordPress admin:** open `/wp-admin` and sign in with the administrator credentials (see section 4). A second, regular user also exists.
- **Adminer:** choose System **MySQL**, Server **mariadb**, then enter the database user, password, and database name (see section 4).
- **FTP:** connect with an FTP client using the FTP user and password. You will land in the WordPress files folder.

---

## 4. Locating and managing credentials

Credentials are **not hard-coded** in the images. They are stored in configuration files on the host and passed to the containers at startup.

| Where | What it contains |
|-------|------------------|
| `srcs/.env` | Domain name, database name, usernames, and other settings. |
| `secrets/` (if used) | Passwords: database root password, database user password, WordPress admin password, FTP password. |

Typical values you will find (names may vary slightly in your files):

- Database name, database user, database password, database root password
- WordPress administrator username and password
- WordPress second user username and password
- FTP username and password

### Good practices

- **Never commit** `.env` or the `secrets/` folder to a public Git repository (they should be in `.gitignore`).
- The WordPress admin username must **not** contain "admin" or "administrator".
- To **change a password**:
  - *WordPress user:* log in to `/wp-admin` → Users → Profile → set a new password.
  - *Database or FTP password:* edit the value in `.env` / `secrets/`, then run `make fclean` followed by `make` so the services are re-created with the new values. ⚠️ `fclean` erases the data; export what you need first.

---

## 5. Checking that the services are running correctly

### 5.1 Quick status of all containers

```bash
docker compose -f srcs/docker-compose.yml ps
```

Every service (nginx, wordpress, mariadb, redis, ftp, adminer, static website) should be shown as **Up / running**.

You can also use:

```bash
docker ps
```

### 5.2 Read the logs of a service

```bash
docker compose -f srcs/docker-compose.yml logs <service-name>
# follow logs live:
docker compose -f srcs/docker-compose.yml logs -f <service-name>
```

Example: `docker compose -f srcs/docker-compose.yml logs mariadb`

### 5.3 Check each service

| Service | How to verify |
|---------|---------------|
| **NGINX / WordPress** | Open `https://hacharka.42.fr` — the site must load. Open `/wp-admin` — the login page must appear. |
| **MariaDB** | Log in to Adminer, or run: `docker exec -it mariadb mariadb -u <db_user> -p` and enter the password. |
| **Redis** | Run `docker exec -it redis redis-cli ping` — the answer must be `PONG`. In WordPress, the Redis Object Cache plugin should show *Connected*. |
| **FTP** | Connect with an FTP client on port 21 using the FTP credentials; you should see the WordPress files. |
| **Adminer** | Open `http://hacharka.42.fr:8080` — the login form must appear. |
| **Static website** | Open `https://hacharka.42.fr/resume/` — the resume page must load. If you get a *502 Bad Gateway*, the `website` container is not running (check its logs). |

### 5.4 Check the data folders

```bash
ls /home/hacharka/data/wordpress
ls /home/hacharka/data/mariadb
```

Both folders should contain files once the stack has started.

### 5.5 Something is not working?

1. Run `docker compose -f srcs/docker-compose.yml ps` to find a container that is stopped or restarting.
2. Read its logs (see 5.2).
3. Make sure `/etc/hosts` contains the domain and that `.env` / `secrets` are filled in.
4. Try `make down` then `make` again.
5. As a last resort, `make re` rebuilds everything from scratch (⚠️ erases all data).