#!/bin/bash

if [ $(id -u) -ne 0 ]
then 
	echo "Please run with sudo or as root"
	exit 1
fi

dnf install -y httpd
dnf install -y php php-mysqlnd php-json php-pecl-zip php-mbstring 

systemctl start httpd
systemctl enable httpd

dnf install -y mariadb-server

### mysql_secure_installation using the echo input
echo "Running Mysql_secure_installation..."
echo -e "\n\nPassword123\nPassword123\n\n\n\n\n" | mysql_secure_installation

curl -LO http://mirror.linuxtrainingacademy.com/phpMyAdmin/phpMyAdmin-5.0.2-all-languages.zip

unzip phpMyAdmin-5.0.2-all-languages.zip

mv phpMyAdmin-5.0.2-all-languages/* /var/www/html

cp /var/www/html/config.sample.inc.php /var/www/html/config.inc.php

# Need to save the value from 
value = $(date | md5sum)

# Add that to the file
vi /var/www/html/config.inc.php

# Under the value
$cfg['blowfish_secret'] = "$value";

mkdir /var/www/html/tmp
chown apache /var/www/html/tmp

