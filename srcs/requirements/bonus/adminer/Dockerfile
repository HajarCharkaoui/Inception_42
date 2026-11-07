FROM debian:bookworm

RUN apt-get update -y && \
    apt-get install -y php-cli php-mysql wget && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/www/adminer && wget "https://adminer.org/latest.php" -O /var/www/adminer/index.php


EXPOSE 8080

ENTRYPOINT ["php", "-S", "0.0.0.0:8080",  "-t",  "/var/www/adminer"]