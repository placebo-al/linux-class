#!/bin/bash

# Variables for configuration
ROOT_PASSWORD="Password123"
ICINGA_DB="icinga"
ICINGA_USER="icinga"
ICINGA_PASSWORD="Password123"
ICINGAWEB_DB="icingaweb"
ICINGAWEB_USER="icingaweb"
ICINGAWEB_PASSWORD="Password123"
TIMEZONE="Australia/Sydney"

# Ensure the script is run as root
if [ $(id -u) -ne 0 ]
then 
	echo "Please run with sudo or as root"
	exit 1
fi

# Install required packages
echo "Installing required packages..."
dnf install -y httpd php php-gd php-intl php-ldap php-opcache mariadb-server expect

# Configure PHP
echo "Configuring PHP..."
cp /etc/php.ini /etc/php.ini.bak
sed -i "s#^;date\.timezone =#date.timezone = \"$TIMEZONE\"#" /etc/php.ini

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


# mysqladmin -u root -p"$ROOT_PASSWORD" create icinga
# mysqladmin -u root -p"$ROOT_PASSWORD" create icingaweb

# mysql -u root -p"$ROOT_PASSWORD" -e 'GRANT ALL on icinga.* to icinga@localhost identified by "$ICINGA_PASSWORD";'
# mysql -u root -p"$ROOT_PASSWORD" -e 'GRANT ALL on icingaweb.* to icingaweb@localhost identified by "$ICINGAWEB_PASSWORD";'
# mysql -u root -p"$ROOT_PASSWORD" -e 'FLUSH PRIVILEGES;'

# Create databases and users
echo "Creating databases and users..."
mysql -u root -p"$ROOT_PASSWORD" <<MYSQL_SCRIPT
CREATE DATABASE $ICINGA_DB;
CREATE DATABASE $ICINGAWEB_DB;
GRANT ALL ON $ICINGA_DB.* TO '$ICINGA_USER'@'localhost' IDENTIFIED BY '$ICINGA_PASSWORD';
GRANT ALL ON $ICINGAWEB_DB.* TO '$ICINGAWEB_USER'@'localhost' IDENTIFIED BY '$ICINGAWEB_PASSWORD';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Install Icinga2 and related packages
echo "Installing Icinga2..."
dnf install -y http://mirror.linuxtrainingacademy.com/icinga/icinga-rpm-release.noarch.rpm
dnf install -y icinga2 icingaweb2 icingacli icinga2-ido-mysql

# sudo dnf -y install https://packages.icinga.com/epel/icinga-rpm-release-8-latest.noarch.rpm
# dnf install -y https://packages.icinga.com/centos/8/release/x86_64/icinga2/icinga2-2.13.10-1.el8.x86_64.rpm


# Configure the Icinga2 database
echo "Configuring the Icinga2 database..."
mysql -u root -p"$ROOT_PASSWORD" $ICINGA_DB < /usr/share/icinga2-ido-mysql/schema/mysql.sql


# To test the install run: mysqlshow -u root -p icinga
# vi /etc/icinga2/features-available/ido-mysql.conf

# Configure Icinga2 to use the database
echo "Configuring Icinga2 for database integration..."
cat <<EOL > /etc/icinga2/features-available/ido-mysql.conf
/**
 * The IdoMysqlConnection type implements MySQL support
 * for DB IDO.
 */
object IdoMysqlConnection "ido-mysql" {
    user = "$ICINGA_USER"
    password = "$ICINGA_PASSWORD"
    host = "localhost"
    database = "$ICINGA_DB"
}
EOL
icinga2 feature enable ido-mysql


# Install and configure plugins
echo "Installing monitoring plugins..."
dnf install -y epel-release
dnf config-manager --set-enabled powertools
dnf install -y nagios-plugins-all

# icinga2 node wizard
# echo -e "n\n\n\n\n\nn" | icinga2 node wizard

# Run Icinga2 node wizard using expect
echo "Configuring Icinga2 node wizard..."
expect <<EOF
spawn icinga2 node wizard
expect "Please specify if this is a satellite setup ('n' installs a master setup) [Y/n]:"
send "n\r"
expect "Please specify the common name (CN) [icinga]:"
send "\r"
expect "Master zone name [master]:"
send "\r"
expect "Do you want to specify additional global zones? [y/N]:"
send "\r"
expect "Bind Host []:"
send "\r"
expect "Bind Port []:"
send "\r"
expect "Do you want to disable the inclusion of the conf.d directory [Y/n]:"
send "n\r"
expect eof
EOF

# Start and enable Icinga2
echo "Starting and enabling Icinga2..."
systemctl start icinga2 && systemctl enable icinga2
systemctl restart httpd


# Output additional setup instructions
echo "Icinga2 setup complete."
echo "Visit the web interface at http://10.23.45.30/icingaweb2/setup"
echo "Run the following commands to obtain the API password and setup token:"
echo "  cat /etc/icinga2/conf.d/api-users.conf"
echo "  icingacli setup token create"


# Web page set up

# Refer to notes



 