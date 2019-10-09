#########################################################################
#LAMP for Raspberry Pi                                                  #
#This script will install Nginx, PHP 7, FTP, and MySQL (MariaDB).       #
#This script was written by Paolo Porqueddu                             #
#Visit my website for more interesting project   www.paolo9785.com      #
#########################################################################

#!/bin/bash

if [ "$(whoami)" != "root" ]; then
	echo "Run script as ROOT please. (sudo !!)"
	exit
fi

#Prerequisites
echo -n "LAMP for Raspberry Pi - Install script 1.0"
echo -n "Upgrading the system before to proceed.."
sudo apt-get update -y
sudo apt-get dist-upgrade -y
sudo apt-get upgrade -y

#Update RPI firmware (optional)
apt-get install -y rpi-update

#helps to prevent hacking attempts by detecting log-in attempts that use a dictionary attack 
#and banning the offending IP address for a short while. 
apt-get install fail2ban

#check current webserver status on the machine

PORT_CHECK = (sudo lsof -nPi | grep ":80 (LISTEN)" | wc -l)


if [ $PORT_CHECK > 0 ] ;then
 echo -n "Found some processes running on port 80."
echo -n "Do you want to check and remove any previous webserver installation (y/n)? "
read answer

  if [ "$answer" != "${answer#[Yy]}" ] ;then
      echo "Ok. Performing clean up..please wait."
      service apache2 stop
      update-rc.d -f apache2 remove
      apt-get remove apache2
  else
      echo "Ok. Skipping thrid webservers presence and starting Nginx install. Please make sure to set a different port on your NGINX to allow cohesistance with other services."
  fi
fi

#install PHP-fpm
echo -n "Installing php-fpm 7.0"
apt-get install -t stretch -y php7.0 php7.0-fpm php7.0-cli php7.0-opcache php7.0-mbstring php7.0-curl php7.0-xml php7.0-gd php7.0-mysql
sudo phpenmod mcrypt
sudo service php7.0-fpm restart

#install Nginx
echo -n "Installing Nginx server"
sudo apt-get install -t stretch nginx

update-rc.d nginx defaults
update-rc.d php7.0-fpm defaults


# change settings on vhosts for automatic redirection to the “index.php” files for the site folders
echo -n "Setting up Nginx configuration"
sed -i 's/index index.html index.htm index.nginx-debian.html;/index index.html index.htm index.php;/g' /etc/nginx/sites-available/default

#configuring php-fpm / Nginx

sed -i 's/^;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/7.0/fpm/php.ini
sed -i 's/# server_names_hash_bucket_size/server_names_hash_bucket_size/' /etc/nginx/nginx.conf

tee -a /etc/nginx/sites-available/default << END
location ~ \.php$ { 
include snippets/fastcgi-php.conf;
 fastcgi_pass unix:/var/run/php/php7.0-fpm.sock;
}
END

#Adjust permissions on webserver folders
echo -n "Adjusting permissions for Nginx"
sudo chown -R www-data:pi /var/www/html/
sudo chmod -R 770 /var/www/html/
sudo chown www-data:www-data /var/www
sudo chmod 744 /var/www



#generate test files file
echo -n "Generating test files"
echo "<?php phpinfo(); ?>" > /var/www/html/index.php
echo 'Nginx work’s !' > /var/www/html/index.html

echo -n Restarting Nginx / php-fpm"
service nginx restart
service php7.0-fpm restart


#MariaDB
echo -n "Installing MySQL server"
sudo apt-get install mariadb-server
echo -n "MariaDB server installed"
echo -n "Configuring MariaDB"
read -s -p "Please chose a root password for MariaDB: " mysqlPass
mysql -u root -p --database="mysql" --execute="UPDATE mysql.user SET Password=PASSWORD('$mysqlPass') WHERE User='root'; FLUSH PRIVILEGES;"

ervice mysql restart



# PhpMyAdmin
read -p "Do you want to install PhpMyAdmin? <y/N> " prompt
if [ "$prompt" = "y" ]; then
	apt-get install -t stretch -y phpmyadmin
	ln -s /usr/share/phpmyadmin /var/www/default/phpmyadmin
	echo "http://192.168.XXX.XXX/phpmyadmin to enter PhpMyAdmin"
fi

apt-get -y autoremove


echo -n "Please open a browser a verify the following 3 pages are showing up properly"
echo -n "http://192.168.1.1/index.html"
echo -n "http://192.168.1.1/index.php"
echo -n "http://192.168.1.1/phpmyadmin"

mysql_secure_installation



