#!/bin/bash

if [ $(id -u) -ne 0 ]
then 
  echo "Please run with sudo or as root"
  exit 1
fi

# Install apache and php
dnf install -y httpd php php-mysqlnd
sudo systemctl start httpd
sudo systemctl enable httpd

# Install Mariadb
dnf install -y mariadb-server
sudo systemctl start mariadb
sudo systemctl enable mariadb

### mysql_secure_installation using the echo input
echo "Running Mysql_secure_installation..."
echo -e "\n\nPassword123\nPassword123\n\n\n\n\n" | mysql_secure_installation

# Create the Hesk database
mysqladmin -u root -pPassword123 create hesk

mysql -u root -pPassword123 -e "GRANT ALL on hesk.* to hesk@localhost identified by 'Password123'"
mysql -u root -pPassword123 -e "FLUSH PRIVILEGES;"

