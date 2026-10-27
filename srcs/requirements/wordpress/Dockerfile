FROM debian:bookworm

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

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp


RUN mkdir -p /var/www/html /run/php

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

COPY tools/wp_setup.sh /usr/local/bin/wp_setup.sh
RUN chmod +x /usr/local/bin/wp_setup.sh

RUN apt-get update -y && apt-get install -y php-redis

EXPOSE 9000

WORKDIR /var/www/html

ENTRYPOINT ["/usr/local/bin/wp_setup.sh"]