# 1. Base image: Debian bookworm (stable w les paquets dyalha 100% active)
FROM debian:bookworm

# 2. Update w Install NGINX w OpenSSL
RUN apt-get update -y && \
    apt-get install -y nginx openssl && \
    rm -rf /var/lib/apt/lists/*

# 3. Créer dossier SSL w générer Self-Signed Certificate
RUN mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/inception.key \
    -out /etc/nginx/ssl/inception.crt \
    -subj "/C=MA/ST=Tetouan/L=Medina/O=1337/OU=Student/CN=hacharka.42.fr"

# 4. Copier la configuration
COPY conf/nginx.conf /etc/nginx/conf.d/default.conf

# 5. Exposer port 443
EXPOSE 443

# 6. Lancer NGINX
CMD ["nginx", "-g", "daemon off;"]