#########################################################################
#LAMP su Raspberry Pi                                                   #
#Questo script installera Nginx, PHP 7, FTP, and MySQL (MariaDB).       #
#Script realizzato da Paolo Porqueddu                                   #
#Visita il blog per tanti altri progetti ( https://www.paolo9785.com )  #
#########################################################################

#!/bin/bash

if [ "$(whoami)" != "root" ]; then
	echo "Esegui lo script da utente root. usa SUDO."
	exit
fi

#Prerequisites
echo -n "LAMP for Raspberry Pi - Install script 1.0"
echo -n "Aggiornamento del sistema prima di procedere.."
sudo apt-get update -y
sudo apt-get dist-upgrade -y
sudo apt-get upgrade -y

#Update RPI firmware (optional)
apt-get install -y rpi-update

apt-get install -y lsof

#helps to prevent hacking attempts by detecting log-in attempts that use a dictionary attack 
#and banning the offending IP address for a short while. 
apt-get install fail2ban -y

#check current webserver status on the machine

PORT_CHECK=$(sudo lsof -nPi | grep ":80 (LISTEN)" | wc -l)


if [ $PORT_CHECK > 0 ] ;then
 echo -n "FAbbiamo trovato alcuni processi già in ascolto sulla porta 80."
echo -n "Vuoi verificare e rimuovere eventuali precedenti installazioni di un web server (S/N)? "
read answer

  if [ "$answer" != "${answer#[Ss]}" ] ;then
      echo "Ok. Pulizia in corso....."
      service apache2 stop
      update-rc.d -f apache2 remove
      apt-get remove apache2 -y
  else
      echo "Ok. Ignoro altre installazioni. Assicurati di impostare una porta differente su NGINX affinchè il nuovo webserver possa coesistere con il precedente."
  fi
fi

#install PHP-fpm
echo -n "Installo php-fpm 7.3"
apt-get install php7.3 php7.3-fpm php7.3-cli php7.3-opcache php7.3-mbstring php7.3-curl php7.3-xml php7.3-gd php7.3-mysql -y
#sudo phpenmod mcrypt #does not exists under 7.3 php.ini
sudo service php7.3-fpm restart

#install Nginx
echo -n "Installo Nginx server"
sudo apt-get install -y nginx

update-rc.d nginx defaults
update-rc.d php7.3-fpm defaults


# change settings on vhosts for automatic redirection to the “index.php” files for the site folders
echo -n "Configurazione di Nginx in corso"
sed -i 's/index index.html index.htm index.nginx-debian.html;/index index.html index.htm index.php;/g' /etc/nginx/sites-available/default
sed -i 's/server_name _;/server_name localhost;/g /etc/nginx/sites-available/default
#configuring php-fpm / Nginx
sed -i 's/^;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/7.3/fpm/php.ini
sed -i 's/# server_names_hash_bucket_size/server_names_hash_bucket_size/' /etc/nginx/nginx.conf

#to verify ---mast not be added at the end of file
tee -a /etc/nginx/sites-available/default << END
location ~ \.php$ { 
include snippets/fastcgi-php.conf;
 fastcgi_pass unix:/var/run/php/php7.3-fpm.sock;
}
END

#Adjust permissions on webserver folders
echo -n "Riconfigurazione dei permessi per Nginx"
sudo chown -R www-data:pi /var/www/html/
sudo chmod -R 770 /var/www/html/
sudo chown www-data:www-data /var/www
sudo chmod 744 /var/www



#generate test files file
echo -n "Generazione file di prova"
echo "<?php phpinfo(); ?>" > /var/www/html/index.php
echo 'Nginx funziona !' > /var/www/html/index.html

echo -n "Riavvio Nginx / php-fpm"
service nginx restart
service php7.3-fpm restart
#MariaDB
echo -n "Installazione di MySQL server"
sudo apt-get install -y mariadb-server mariadb-client
echo -n "MariaDB server installato"
echo -n "Configurazione impostazioni di sicurezza per MariaDB"
mysql_secure_installation
service mysql restart
# PhpMyAdmin
read -p "Voui installare PhpMyAdmin? <s/N> " prompt
if [ "$prompt" = "y" ]; then
	echo " Nginx non è disponibile sulla lista, premi TAB piuttosto che selezionare la voce errata."
	apt-get install -y phpmyadmin
	sudo apt install php7.1-mcrypt
	sudo ln -s /etc/php/7.1/mods-available/mcrypt.ini /etc/php/7.3/mods-available/
	sudo phpenmod mcrypt
	ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin
	
	echo "http://192.168.XXX.XXX/phpmyadmin per accedere PhpMyAdmin"
fi
apt-get -y autoremove
echo -n "Installazione completata"
echo -n "Prova i seguenti link sul tuo browser per verificare che l'installazione sia andata a buon fine. "
echo -n "http://192.168.1.1/index.html"
echo -n "http://192.168.1.1/index.php"
echo -n "http://192.168.1.1/phpmyadmin"
