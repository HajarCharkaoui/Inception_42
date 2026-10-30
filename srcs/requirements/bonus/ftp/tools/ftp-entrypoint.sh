#!/bin/bash
set -e

mkdir -p /var/run/vsftpd/empty
FTP_PASS=$(cat /run/secrets/ftp_user_password | tr -d '\r\t')

if ! id "$FTP_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$FTP_USER"
    echo "$FTP_USER:$FTP_PASS" | chpasswd
    usermod -d /var/www/html "$FTP_USER"
fi


usermod -aG www-data "$FTP_USER"
chown -R www-data:www-data /var/www/html
chmod -R 775 /var/www/html

exec /usr/sbin/vsftpd /etc/vsftpd.conf