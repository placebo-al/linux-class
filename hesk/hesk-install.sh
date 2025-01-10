#!/bin/bash

if [ $(id -u) -ne 0 ]
then 
  echo "Please run with sudo or as root"
  exit 1
fi

# Install apache and php
dnf install -y httpd php php-mysqlnd
systemctl start httpd
systemctl enable httpd

# Install Mariadb
dnf install -y mariadb-server
systemctl start mariadb
systemctl enable mariadb

### mysql_secure_installation using the echo input
echo "Running Mysql_secure_installation..."
echo -e "\n\nPassword123\nPassword123\n\n\n\n\n" | mysql_secure_installation

# Create the Hesk database
mysqladmin -u root -pPassword123 create hesk

mysql -u root -pPassword123 -e "GRANT ALL on hesk.* to hesk@localhost identified by 'Password123'"
mysql -u root -pPassword123 -e "FLUSH PRIVILEGES;"

curl -LO http://mirror.linuxtrainingacademy.com/hesk/hesk.zip

cd /var/www/html
unzip /home/vagrant/hesk.zip

chown apache hesk_settings.inc.php
chown apache attachments
chown apache cache
chown apache language/en/emails

# From here we need the web edit