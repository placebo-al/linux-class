#!/bin/bash

if [ $(id -u) -ne 0 ]
then 
	echo "Please run with sudo or as root"
	exit 1
fi


dnf install -y httpd php php-gd php-intl php-ldap php-opcache

cp /etc/php.ini /etc/php.ini.bak
# vi /etc/php.ini			# Change to what the edit is
sed -i 's#^;date\.timezone =#date.timezone = "Australia/Sydney"#' /etc/php.ini

systemctl enable --now httpd

dnf install -y mariadb-server
systemctl start mariadb
systemctl enable mariadb

### mysql_secure_installation using the echo input
echo "Running Mysql_secure_installation..."
echo -e "\n\nPassword123\nPassword123\n\n\n\n\n" | mysql_secure_installation

mysqladmin -u root -pPassword123 create icinga
mysqladmin -u root -pPassword123 create icingaweb

mysql -u root -pPassword123 -e 'GRANT ALL on icinga.* to icinga@localhost identified by "Password123";'
mysql -u root -pPassword123 -e 'GRANT ALL on icingaweb.* to icingaweb@localhost identified by "Password123";'
mysql -u root -pPassword123 -e 'FLUSH PRIVILEGES;'

# sudo dnf install -y http://mirror.linuxtrainingacademy.com/icinga/icinga-rpm-release.noarch.rpm
dnf install -y epel-release
dnf config-manager --set-enable powertools

sudo dnf -y install https://packages.icinga.com/epel/icinga-rpm-release-8-latest.noarch.rpm
# dnf install -y https://packages.icinga.com/centos/8/release/x86_64/icinga2/icinga2-2.13.10-1.el8.x86_64.rpm

# dnf install -y icinga2 icingaweb2 icingacli icinga2-ido-mysql

# mysql -u root -pPassword123 icinga < /usr/share/icinga2-ido-mysql/schema/mysql.sql

# # To test the install run: mysqlshow -u root -p icinga
# # vi /etc/icinga2/features-available/ido-mysql.conf		# Change to what the edit is
# echo '/**
# * The IdoMysqlConnection type implements MySQL support
# * for DB IDO.
# */
# object IdoMysqlConnection "ido-mysql" {
# user = "icinga"
# password = "icinga123"
# host = "localhost"
# database = "icinga"
# }
# ' > /etc/icinga2/features-available/ido-mysql.conf

# icinga2 feature enable ido-mysql
# # icinga2 feature list
# # dnf install -y epel-release
# # dnf config-manager --set-enable powertools
# dnf install -y nagios-plugins-all

# # icinga2 node wizard   					## Will have to get the details from this wizard
# # Enter n enter enter enter enter  enter n
# echo -e 'n\n\n\n\n\nn\n'

# systemctl start icinga2
# systemctl enable icinga2
# systemctl restart httpd

# # cat /etc/icinga2/conf.d/api-users.conf	## Will have to get the details from this wizard
# # icingacli setup token create				## Will have to get the details from this wizard

# # Web page set up

