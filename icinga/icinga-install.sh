#!/bin/bash

# Variables for configuration
export ROOT_PASSWORD="Password123"
ICINGA_PASSWORD="Password123"
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

# Install Icinga2 and related packages
echo "Installing Icinga2..."
dnf install -y http://mirror.linuxtrainingacademy.com/icinga/icinga-rpm-release.noarch.rpm
dnf install -y icinga2 icingaweb2 icingacli icinga2-ido-mysql

# sudo dnf -y install https://packages.icinga.com/epel/icinga-rpm-release-8-latest.noarch.rpm
# dnf install -y https://packages.icinga.com/centos/8/release/x86_64/icinga2/icinga2-2.13.10-1.el8.x86_64.rpm

echo "Installing monitoring plugins..."
dnf install -y epel-release
dnf config-manager --set-enabled powertools
dnf install -y nagios-plugins-all


# Configure PHP
echo "Configuring PHP..."
cp /etc/php.ini /etc/php.ini.bak
sed -i "s#^;date\.timezone =#date.timezone = \"$TIMEZONE\"#" /etc/php.ini

# Start and enable Apache services
systemctl start httpd && systemctl enable httpd
if ! systemctl is-active --quiet httpd; then
    echo "Failed to start Apache." > /dev/error
    exit 1
fi

# Start and enable Mariadb services
systemctl start mariadb && systemctl enable mariadb
if ! systemctl is-active --quiet mariadb; then
    echo "Failed to start MariaDB." > /dev/error
    exit 1
fi


# This method actually works, can't say the same for expect :-(
echo -e "\n\n${ROOT_PASSWORD}\n${ROOT_PASSWORD}\n\n\n\n\n" | mysql_secure_installation

# Create databases and users

mysql -u root --password="${ROOT_PASSWORD}" <<EOF
CREATE DATABASE icinga;
CREATE DATABASE icingaweb;
CREATE USER 'icinga'@'localhost' IDENTIFIED BY '$ICINGA_PASSWORD';
CREATE USER 'icingaweb'@'localhost' IDENTIFIED BY '$ICINGAWEB_PASSWORD';
GRANT ALL PRIVILEGES ON icinga.* TO 'icinga'@'localhost';
GRANT ALL PRIVILEGES ON icingaweb.* TO 'icingaweb'@'localhost';
FLUSH PRIVILEGES;
EOF


# Configure the Icinga2 database
echo "Configuring the Icinga2 database..."
mysql -u root --password="${ROOT_PASSWORD}" icinga < /usr/share/icinga2-ido-mysql/schema/mysql.sql


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


# Run Icinga2 node wizard using expect
echo "Configuring Icinga2 node wizard..."
echo ""

echo -e "n\n\n\nN\n\n\nn\n" | icinga2 node wizard


# Start and enable Icinga2
echo "Starting and enabling Icinga2..."
systemctl start icinga2 && systemctl enable icinga2
if ! systemctl is-active --quiet icinga2; then
    echo "Failed to start Icinga2." > /dev/error
    exit 1
fi

systemctl restart httpd
if ! systemctl is-active --quiet httpd; then
    echo "Failed to start Httpd." > /dev/error
    exit 1
fi


# Output additional setup instructions
echo "Icinga2 setup complete."
printf '%.0s-' {1..60}; echo
echo "Visit the web interface at http://10.23.45.30/icingaweb2/setup"
printf '%.0s-' {1..60}; echo
echo ""
echo "Run the following commands to obtain the API password and setup token:"
printf '%.0s-' {1..60}; echo
echo "  cat /etc/icinga2/conf.d/api-users.conf"
printf '%.0s-' {1..60}; echo
echo "  icingacli setup token create"
printf '%.0s-' {1..60}; echo
echo ""
echo "Going to add the influxdb logging"


icinga2 feature enable influxdb

influx_file="/etc/icinga2/features-enabled/influxdb.conf"

sed -i '/object InfluxdbWriter "influxdb"/a \
host = "10.23.45.40"\
database = "icinga2"\
enable_send_metadata = true' "$influx_file"

systemctl restart icinga2

echo ""
printf '%.0s-' {1..60}; echo
echo "Install monitoring and configure sending metrics to Grafana"
printf '%.0s-' {1..60}; echo
echo ""

dnf install -y http://mirror.linuxtrainingacademy.com/grafana/telegraf-1.15.3-1.x86_64.rpm

telegraf_file="/etc/telegraf/telegraf.conf"

sed -i '/\[\[outputs\.influxdb\]\]/a\urls = ["http://10.23.45.40:8086"]' $telegraf_file
sed -i '/^# \[\[inputs\.\(conntrack\|internal\|interrupts\|linux_sysctl_fs\|net\|netstat\|nstat\)\]\]/s/^# //' $telegraf_file

systemctl start telegraf && systemctl enable telegraf
if ! systemctl is-active --quiet telegraf; then
    echo "Failed to start Telegraf."
    exit 1
fi
