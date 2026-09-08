#!/bin/bash
set -e

# T-aaked bli l-dossier d socket w pid kayn
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql

# Verifier wach l-database deja m-initialisya
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    echo "Initializing MariaDB database..."
    
# Initialiser datadir b mysql_install_db
mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

# Lancer mysqld temporaire f l-arriere plan bach n-passiw l-commandes SQL
mysqld_safe --datadir=/var/lib/mysql --skip-networking &
pid="$!"

# Tsenna hta ykoun MariaDB wajed bach ystqbel les requetes
until mysqladmin ping --silent; do
    sleep 1
done

# 4. Creer database w users m3a les droits kamlin
    mariadb -u root << EOF
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

    # 5. Wqef mysqld l-mo2eqqat
    mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
    wait "$pid"
    echo "Database initialization finished."
fi

# 6. Demarrer MariaDB f l-foreground b configuration kamla
exec mysqld_safe --datadir=/var/lib/mysql