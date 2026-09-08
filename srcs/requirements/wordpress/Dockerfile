# 1. Base image: Debian bookworm
FROM debian:bookworm

# 2. Install PHP 8.2 extensions, curl, w mariadb-client
RUN apt-get update -y && \
    apt-get install -y \
    php8.2-fpm \
    php8.2-mysql \
    php8.2-curl \
    php8.2-gd \
    php8.2-intl \
    php8.2-mbstring \
    php8.2-xml \
    php8.2-zip \
    mariadb-client \
    curl \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# 3. Installer WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# 4. Créer dossiers
RUN mkdir -p /var/www/html /run/php

# 5. Copier la configuration f path dyal PHP 8.2
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

# 6. Copier script setup
COPY tools/wp_setup.sh /usr/local/bin/wp_setup.sh
RUN chmod +x /usr/local/bin/wp_setup.sh

# 7. Expose
EXPOSE 9000

# 8. Workdir
WORKDIR /var/www/html

# 9. Entrypoint
ENTRYPOINT ["/usr/local/bin/wp_setup.sh"]