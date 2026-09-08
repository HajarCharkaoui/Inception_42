#!/bin/bash
# set -e

# # T-aaked mn les permissions d les dossiers
# mkdir -p /run/mysqld
# chown -R mysql:mysql /run/mysqld
# chown -R mysql:mysql /var/lib/mysql

# # Ila kan l-dossier system 'mysql' ma kaynch, ya3ni awel merra ghadi t-initialisa
# if [ ! -d "/var/lib/mysql/mysql" ]; then
#     echo "Initializing MariaDB system tables..."
#     mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

#     echo "Creating database and users..."
#     # Lancer mysqld temporaire sans réseau
#     mysqld_safe --datadir=/var/lib/mysql --skip-networking &
#     pid="$!"

#     # Tsenna le socket y-wjed
#     while ! mysqladmin ping --silent; do
#         sleep 1
#     done

#     # Exécuter les commandes SQL
#     mariadb -u root << EOF
# FLUSH PRIVILEGES;
# CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
# CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
# GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
# ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
# FLUSH PRIVILEGES;
# EOF

#     # Stop temporary server
#     mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
#     wait "$pid"
#     echo "MariaDB initialization complete."
# fi

# # Demarrer MariaDB standard f l-foreground
# echo "Starting standard MariaDB..."
# exec mysqld_safe --datadir=/var/lib/mysql




set -e

# Qad les permissions d les dossiers
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql

# Ila kan l-volume khawi f l-host, initialisi l-fichiers de base
if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
fi

# Sawbi fichier SQL temporaire f /tmp
SQL_INIT="/tmp/init.sql"

cat << EOF > ${SQL_INIT}
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

echo "Starting MariaDB with init file..."
# Lancer MariaDB m3a l-fichier li ghay-créer l-base w l-users direct
exec mysqld_safe --datadir=/var/lib/mysql --init-file=${SQL_INIT}