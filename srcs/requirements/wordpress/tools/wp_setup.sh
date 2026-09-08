#!/bin/bash
set -e

# Tsenna MariaDB hta tkoun online
echo "Waiting for MariaDB..."
until mysqladmin ping -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent; do
    sleep 2
done
echo "MariaDB is ready!"

# Dossier d travail
cd /var/www/html

# Telechargi w initialisi WordPress ila kan baqi ma kaynch
if [ ! -f "wp-config.php" ]; then
    echo "Downloading and configuring WordPress..."

    # Telechargi les fichiers de base de WordPress
    wp core download --allow-root

    # Générer le fichier wp-config.php m3a les variables d'environnement
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="mariadb:3306" \
        --allow-root

    # Installer WordPress w créer l-Admin user
    wp core install \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception 42" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    # Créer le 2ème user (Normal user b rôle author) kima taleb le sujet
    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}" \
        --allow-root

    echo "WordPress configured successfully!"
fi

# T-aaked mn les permissions dyal les fichiers l www-data
chown -R www-data:www-data /var/www/html

# Lancer PHP-FPM f l-foreground (PID 1)
echo "Starting PHP-FPM..."
exec php-fpm8.2 -F