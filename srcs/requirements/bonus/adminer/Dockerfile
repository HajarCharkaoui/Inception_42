FROM debian:bookworm

RUN apt-get update -y && \
    apt-get install -y php-cli php-mysql wget && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/adminer && wget "https://adminer.org/latest.php" -O /var/www/adminer/index.php

COPY tools/adminer-entrypoint.sh /usr/local/bin/adminer-entrypoint.sh
RUN chmod +x /usr/local/bin/adminer-entrypoint.sh


EXPOSE 8080

ENTRYPOINT [ "/usr/local/bin/adminer-entrypoint.sh" ]