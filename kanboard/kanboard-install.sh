#!/bin/bash

if [ $(id -u) -ne 0 ]
then 
	echo "Please run with sudo or as root"
	exit 1
fi

dnf install -y httpd php php-mysqlnd php-gd php-mbstring php-json php-xml

systemctl start httpd
systemctl enable httpd

dnf install -y mariadb-server
systemctl start mariadb-server
systemctl enable mariadb-server

### mysql_secure_installation using the echo input
echo "Running Mysql_secure_installation..."
echo -e "\n\nPassword-to-change\nPassword-to-change\n\n\n\n\n" | mysql_secure_installation

mysqladmin create kanboard

mysql -e "GRANT ALL on kanboard.* to kanboard@localhost identified by '<password>';"
mysql -e "FLUSH PRIVILEGES;"


curl -LO http://mirror.linuxtrainingacademy.com/kanboard/kanboard-v1.2.15.zip

unzip kanboard-v1.2.15.zip

mv kanboard-v1.2.15/* /var/www/html/


echo "
?php
define('DB_DRIVER', 'mysql');
define('DB_USERNAME', 'kanboard');
define('DB_PASSWORD', '<password>');
define('DB_HOSTNAME', 'localhost');
define('DB_NAME', 'kanboard');
" >> /var/www/html/config.php



