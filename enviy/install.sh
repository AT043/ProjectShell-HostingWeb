#!/bin/bash

echo "update repo..."
#sudo apt-get update

echo "install bind dnsutils..."
sudo apt-get install bind9 dnsutils
echo "Ganti ip pada file domain, ip, dan named.conf.default-zones sesuai ip masing2"
echo "ganti juga ip di resolv.conf"
sleep 10s
echo ";..............;"
echo "sudah ganti?"
echo "1. sudah"
echo "2. belum"
read jawab

if [ $jawab -eq 1 ]; then
echo "lanjut...."
else 
exit
fi

sudo cp domain  /etc/bind/domain
sudo cp ip /etc/bind/ip
sudo rm /etc/bind/named.conf.default-zones
sudo cp named.conf.default-zones /etc/bind/
sudo rm /etc/resolv.conf
sudo cp resolv.conf /etc/resolv.conf

echo "install apache2.."
sudo apt-get install apache2

echo "stop nginx.."
sudo service nginx stop

echo "install mariadb.."
sudo apt-get install mariadb-server -y

echo "install php..."
sudo apt-get install php php-zip php-intl php-curl php-mbstring php-mysql unzip -y

echo "download phpmyadmin.."
sudo mv config.inc.php /var/www/html
cd /var/www/html
sudo wget https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.zip
sudo unzip phpMyAdmin-5.2.1-all-languages.zip
sudo mv phpMyAdmin-5.2.1-all-languages phpmyadmin
sudo rm phpMyAdmin-5.2.1-all-languages.zip
sudo mv config.inc.php phpmyadmin/
cd phpmyadmin/
sudo chown www-data:www-data -R /var/www/html/phpmyadmin/

echo "end.."

