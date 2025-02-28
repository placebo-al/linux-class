#!/bin/bash

if [ $(id -u) -ne 0 ]
then
	echo "Please run with sudo or as root"
	exit 1
fi

# Install Apache, PHP, and PHP modules
echo "Installing Apache and PHP..."
dnf -q install -y httpd php php-mysqlnd php-json mariadb-server

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

# Create a wordpress database
mysqladmin create wordpress

# Create a user for the wordpress database
mysql -e "GRANT ALL on wordpress.* to wordpress@localhost identified by '<password>';"
mysql -e "FLUSH PRIVILEGES;"

# # Secure MariaDB with echo key presses
echo "Running Mysql_secure_installation..."
echo -e "\n\n${ROOT_PASSWORD}\n${ROOT_PASSWORD}\n\n\n\n\n" | mysql_secure_installation

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
# send "$ROOT_PASSWORD\r"
# expect "Re-enter new password:"
# send "$ROOT_PASSWORD\r"
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

# Download and extract Wordpress
echo "Downloading and installing Wordpress"
TMP_DIR=$(mktemp -d)
cd $TMP_DIR
curl -sOL https://wordpress.org/wordpress-6.7.1.tar.gz
tar zxf wordpress-6.7.1.tar.gz
mv wordpress/* /var/www/html

# Clean up 
cd /
rm -rf $TMP_DIR

# Install the wpi-cli tool
curl -sOL https://raw.github.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp
chmod 755 /usr/local/bin/wp

# Configure wordpress
cd /var/www/html
/usr/local/bin/wp core config --dbname=wordpress --dbuser=wordpress --dbpass=<password>

# Install wordpress
/usr/local/bin/wp core install --url=http://10.23.45.60 --title="Blog" --admin_user="admin" --admin_password="admin" \
	--admin_email="vagrant@localhost.localdomain"

