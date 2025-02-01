#!/bin/bash

# Variables for configuration
ROOT_PASSWORD="Password123"
KANBOARD_DB="kanboard"
KANBOARD_USER="kanboard"
KANBOARD_PASSWORD="Password123"
KANBOARD_URL="https://github.com/kanboard/kanboard/archive/refs/tags/v1.2.15.zip"
# KANBOARD_URL="http://mirror.linuxtrainingacademy.com/kanboard/kanboard-v1.2.15.zip"
KANBOARD_ZIP="kanboard.zip"
KANBOARD_INSTALL_DIR="/var/www/html"

if [ $(id -u) -ne 0 ]
then 
	echo "Please run with sudo or as root"
	exit 1
fi

dnf install -y httpd php php-mysqlnd php-gd php-mbstring php-json php-xml mariadb-server

# Start and enable Apache services
systemctl start httpd && systemctl enable httpd
if ! systemctl is-active --quiet httpd; then
    echo "Failed to start Apache." > /dev/stderr
    exit 1
fi

# Start and enable Mariadb services
systemctl start mariadb && systemctl enable mariadb
if ! systemctl is-active --quiet mariadb; then
    echo "Failed to start MariaDB." > /dev/stderr
    exit 1
fi

### mysql_secure_installation using the echo input
# echo "Running Mysql_secure_installation..."
echo -e "\n\nPassword123\nPassword123\n\n\n\n\n" | mysql_secure_installation

# Not working as expected
# Secure Mariadb installation
# echo "Securing MariaDB..."
# yum install -y expect
# expect <<EOF
# spawn mysql_secure_installation
# expect "Enter current password for root (enter for none):"
# send "\r"
# expect "Set root password? [Y/n]"
# send "Y\r"
# expect "New password:"
# send "${ROOT_PASSWORD}\r"
# expect "Re-enter new password:"
# send "${ROOT_PASSWORD}\r"
# expect "Remove anonymous users? [Y/n]"
# send "Y\r"
# expect "Disallow root login remotely? [Y/n]"
# send "Y\r"
# expect "Remove test database and access to it? [Y/n]"
# send "Y\r"
# expect "Reload privilege tables now? [Y/n]"
# send "Y\r"
# expect eof
# EOF

# mysqladmin -u root -pPassword123 create kanboard
# mysql -u root -pPassword123 -e "GRANT ALL on kanboard.* to kanboard@localhost identified by 'Password123';"
# mysql -u root -pPassword123 -e "FLUSH PRIVILEGES;"

# Create Kanboard database and user
echo "Setting up the Kanboard database..."
# mysqladmin -u root -p"$ROOT_PASSWORD" create "$KANBOARD_DB"
# mysql -u root -p"$ROOT_PASSWORD" -e "GRANT ALL ON $KANBOARD_DB.* TO '$KANBOARD_USER'@'localhost' IDENTIFIED BY '$KANBOARD_PASSWORD';"
# mysql -u root -p"$ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"

mysqladmin -u root -p"${ROOT_PASSWORD}" create "${KANBOARD_DB}"
if [ $? -ne 0 ]; then
    echo "Failed to create database ${KANBOARD_DB}"
    exit 1
fi

mysql -u root -p"${ROOT_PASSWORD}" -e "GRANT ALL ON ${KANBOARD_DB}.* TO '${KANBOARD_USER}'@'localhost' IDENTIFIED BY '${KANBOARD_PASSWORD}';"
if [ $? -ne 0 ]; then
    echo "Failed to grant privileges on ${KANBOARD_DB} to ${KANBOARD_USER}"
    exit 1
fi

mysql -u root -p"${ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"
if [ $? -ne 0 ]; then
    echo "Failed to flush privileges in MySQL"
    exit 1
fi


# Download and install Kanboard
echo "Downloading and installing Kanboard..."
curl -L "$KANBOARD_URL" --output "$KANBOARD_ZIP"
if [ $? -ne 0 ]; then
    echo "Failed to download Kanboard."
    exit 1
fi

unzip "$KANBOARD_ZIP"
if [ $? -ne 0 ]; then
    echo "Failed to unzip Kanboard."
    exit 1
fi

mv kanboard*/* "$KANBOARD_INSTALL_DIR"
rm -rf kanboard* "$KANBOARD_ZIP"


# Configure Kanboard
echo "Configuring Kanboard..."
cat <<EOL > "$KANBOARD_INSTALL_DIR/config.php"
<?php
define('DB_DRIVER', 'mysql');
define('DB_USERNAME', '$KANBOARD_USER');
define('DB_PASSWORD', '$KANBOARD_PASSWORD');
define('DB_HOSTNAME', 'localhost');
define('DB_NAME', '$KANBOARD_DB');
EOL

# Set appropriate permissions
chown -R apache:apache "$KANBOARD_INSTALL_DIR"
chmod -R 755 "$KANBOARD_INSTALL_DIR"

echo "Kanboard setup is complete."
echo "Access it at http://10.23.45.25/"
echo ""
echo "Install monitoring and configure sending metrics to Grafana"

sudo dnf install -y http://mirror.linuxtrainingacademy.com/grafana/telegraf-1.15.3-1.x86_64.rpm

config_file="/etc/telegraf/telegraf.conf"

sed -i '/\[\[outputs\.influxdb\]\]/a\urls = ["http://10.23.45.40:8086"]' $config_file
sed -i '/^# \[\[inputs\.\(conntrack\|internal\|interrupts\|linux_sysctl_fs\|net\|netstat\|nstat\)\]\]/s/^# //' $config_file

systemctl start telegraf && systemctl enable telegraf
if ! systemctl is-active --quiet telegraf; then
    echo "Failed to start Telegraf." > /dev/stderr
    exit 1
fi

