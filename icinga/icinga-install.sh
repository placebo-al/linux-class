#!/bin/bash

if [ $(id -u) -ne 0 ]
then 
	echo "Please run with sudo or as root"
	exit 1
fi


dnf install -y httpd php php-gd php-intl php-ldap php-opcache

# cp /etc/php.ini /etc/php.ini.bak
# vi /etc/php.ini

systemctl enable --now httpd

dnf install -y mariadb-server
systemctl start mariadb-server
systemctl enable mariadb-server

### mysql_secure_installation using the echo input
echo "Running Mysql_secure_installation..."
echo -e "\n\nPassword-to-change\nPassword-to-change\n\n\n\n\n" | mysql_secure_installation

# mysqladmin -u root -p create icinga
# mysqladmin -u root -p create icingaweb
# mysql -u root -p
# dnf install -y http://mirror.linuxtrainingacademy.com/icinga/icinga-rpm-release.noarch.rpm
# dnf install -y icinga2 icingaweb2 icingacli icinga2-ido-mysql
# mysql -u root -p icinga < /usr/share/icinga2-ido-mysql/schema/mysql.sql
# mysqlshow -u root -p icinga
# vi /etc/icinga2/features-available/ido-mysql.conf
# icinga2 feature enable ido-mysql
# icinga2 feature list
# dnf install -y epel-release
# dnf config-manager --set-enable powertools
# dnf install -y nagios-plugins-all
# icinga2 node wizard
# systemctl start icinga2
# systemctl enable icinga2
# systemctl restart httpd
# cat /etc/icinga2/conf.d/api-users.conf
# icingacli setup token create
