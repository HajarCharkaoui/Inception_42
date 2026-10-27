FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y python3 && rm -rf /var/lib/apt/lists/*


WORKDIR /var/www/html

COPY index.html .

EXPOSE 3000

CMD ["python3", "-m", "http.server", "3000"]