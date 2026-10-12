FROM debian:bookworm

RUN apt-get update -y && apt-get install -y vsftpd && \
    mkdir -p /var/run/vsftpd/empty && rm -rf /var/lib/apt/lists/*


COPY conf/vsftpd.conf /etc/vsftpd.conf
COPY tools/ftp-entrypoint.sh /usr/local/bin/ftp-entrypoint.sh


RUN chmod +x /usr/local/bin/ftp-entrypoint.sh

EXPOSE 21 21000-21005


ENTRYPOINT [ "/usr/local/bin/ftp-entrypoint.sh" ]