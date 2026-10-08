FROM debian:bookworm

RUN apt-get update -y && \
    apt-get install -y redis-server php-redis && rm -rf /var/lib/apt/lists/*


RUN sed -i "s/bind 127.0.0.1/bind 0.0.0.0/g" /etc/redis/redis.conf && \
    sed -i "s/protected-mode yes/protected-mode no/g" /etc/redis/redis.conf && \
    echo "maxmemory 256mb" >> /etc/redis/redis.conf && \
    echo "maxmemory-policy allkeys-lru" >> /etc/redis/redis.conf

EXPOSE 6379

CMD ["redis-server", "--protected-mode", "no"]