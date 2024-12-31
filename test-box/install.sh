# Installing Apache
sudo dnf -y install httpd
sudo systemctl start httpd
sudo systemctl enable httpd

# Installing Mariadb
dnf install -y mariadb-server
systemctl start mariadb
systemctl enable mariadb

# Installing PHP
dnf install -y php php-mysqlnd
sudo systemctl reload httpd
sudo systemctl restart httpd


