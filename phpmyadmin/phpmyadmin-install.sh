#!/bin/bash

# Variables for configuration

PHP_MYADMIN_DIR="/var/www/html"
TMP_DIR="$PHP_MYADMIN_DIR/tmp"
ROOT_PASSWORD="Password123"

if [ $(id -u) -ne 0 ]
then 
	echo "Please run with sudo or as root"
	exit 1
fi

dnf install -y httpd php php-mysqlnd php-json php-pecl-zip php-mbstring mariadb-server

# Start and enable Apache services
systemctl start httpd && systemctl enable httpd
if ! systemctl is-active --quiet httpd; then
    echo "Failed to start Apache."
    exit 1
fi

# Start and enable Mariadb services
systemctl start mariadb && systemctl enable mariadb
if ! systemctl is-active --quiet mariadb; then
    echo "Failed to start MariaDB."
    exit 1
fi

### mysql_secure_installation using the echo input
# echo "Running Mysql_secure_installation..."
# echo -e "\n\nPassword123\nPassword123\n\n\n\n\n" | mysql_secure_installation

# Secure Mariadb installation
echo "Securing MariaDB..."
yum install -y expect
expect <<EOF
spawn mysql_secure_installation
expect "Enter current password for root (enter for none):"
send "\r"
expect "Set root password? [Y/n]"
send "Y\r"
expect "New password:"
send "$ROOT_PASSWORD\r"
expect "Re-enter new password:"
send "$ROOT_PASSWORD\r"
expect "Remove anonymous users? [Y/n]"
send "Y\r"
expect "Disallow root login remotely? [Y/n]"
send "Y\r"
expect "Remove test database and access to it? [Y/n]"
send "Y\r"
expect "Reload privilege tables now? [Y/n]"
send "Y\r"
expect eof
EOF

# curl -LO http://mirror.linuxtrainingacademy.com/phpMyAdmin/phpMyAdmin-5.0.2-all-languages.zip
curl -LO https://files.phpmyadmin.net/phpMyAdmin/5.0.2/phpMyAdmin-5.0.2-all-languages.zip

if ! file phpMyAdmin-5.0.2-all-languages.zip | grep -q "Zip archive data"; then
    echo "Download failed or file corrupted."
    exit 1
fi

unzip phpMyAdmin-5.0.2-all-languages.zip
mv phpMyAdmin-5.0.2-all-languages/* $PHP_MYADMIN_DIR/
rm -rf phpMyAdmin-5.0.2-all-languages*

# Configure phpMyAdmin
cp $PHP_MYADMIN_DIR/config.sample.inc.php $PHP_MYADMIN_DIR/config.inc.php
value=$(date | md5sum | awk '{print $1}')
config_file="$PHP_MYADMIN_DIR/config.inc.php"
sed -i "s|^\(\$cfg\['blowfish_secret'\] = \).*|\1'$value';|" "$config_file"

# Set up tmp directory
mkdir -p $TMP_DIR
chown apache $TMP_DIR

echo "phpMyAdmin setup complete. Access it at http://10.23.45.35/"

# http://10.23.45.35/
# Login is root and password set above

# Further practice suggestions
# User name: webapp01
# Host name: localhost (Select "Local" in the drop-down box.)
# Password: webapp01pass123
# Re-type: webapp01pass123
# Create database with same name and grant all privileges: Click the check box