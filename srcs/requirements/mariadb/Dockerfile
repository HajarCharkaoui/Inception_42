# 1. Base image: Debian bookworm
FROM debian:bookworm

# 2. Update w Install MariaDB
RUN apt-get update -y && \
    apt-get install -y mariadb-server mariadb-client && \
    rm -rf /var/lib/apt/lists/*

# 3. Copier la configuration
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
RUN chmod 644 /etc/mysql/mariadb.conf.d/50-server.cnf

# 4. Copier script setup
COPY tools/mariadb_setup.sh /usr/local/bin/mariadb_setup.sh
RUN chmod +x /usr/local/bin/mariadb_setup.sh

# 5. Expose le port
EXPOSE 3306

# 6. Entrypoint
ENTRYPOINT ["/usr/local/bin/mariadb_setup.sh"]