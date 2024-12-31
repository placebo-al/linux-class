sudo dnf install -y httpd php php-mysqlnd php-gd php-mbstring php-json php-xml

sudo systemctl start httpd
sudo systemctl enable httpd

sudo dnf install -y mariadb-server
sudo systemctl start mariadb-server
sudo systemctl enable mariadb-server

sudo mysql_secure_installation
# have to add the input command

mysqladmin -u root -p create kanboard

# mysql -u root -p
# GRANT ALL on kanboard.* to kanboard@localhost identified by '<password>';
# FLUSH PRIVILEGES;
# exit

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



