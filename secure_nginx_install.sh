#########################################################################
#Hardening NGINX on Raspberry Pi  with SSL/TLS                          #
#This script will enforce security on Nginx server previously installed.#
#This script was written by Paolo Porqueddu                             
#########################################################################

#!/bin/bash

mkdir /etc/nginx/ssl/
cd /etc/nginx/ssl/
openssl genrsa -aes256 -out nginx.key 1024
openssl req -new -key nginx.key -out nginx.csr
openssl x509 -req -days 365 -in nginx.csr -signkey nginx.key -out nginx.crt


#edit /etc/nginx/sites-enabled/default

#server {
#        listen 192.168.0.100:443 ssl;
#        root /var/www/html;
#        index index.html index.htm index.nginx-debian.html;
#        server_name _;
#        ssl_certificate /etc/nginx/ssl/nginx.crt;
#        ssl_certificate_key /etc/nginx/ssl/nginx.key;
#        ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;


sed -i 's/static char ngx_http_server_string[] = "Server: nginx" CRLF;/static char ngx_http_server_string[] = "Server: Unknown" CRLF;/' /src/http/ngx_http_header_filter_module.c
sed -i 'static char ngx_http_server_full_string[] = "Server: " NGINX_VER CRLF;/static char ngx_http_server_full_string[] = "Server: Unknown";/' /src/http/ngx_http_header_filter_module.c

#create diffie-hellman

openssl dhparam -out /etc/nginx/ssl.crt/server.dh_pem 4096;
echo "ssl_dhparam /etc/nginx/ssl.crt/server.dh_pem;" >> /etc/nginx/nginx-includes.conf

systemctl restart nginx
