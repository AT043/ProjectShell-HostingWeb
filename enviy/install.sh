#!/bin/bash

echo "update repo..."
sudo apt-get update

echo "download file2 untuk instalasi..."
sudo git clone https://github.com/at043/projectShell1.git

cd projectShell1/enviy

echo "install bind dnsutils..."
sudo apt-get install bind9 dnsutils
echo "Ganti ip pada file domain, ip, dan named.conf.default-zones sesuai ip masing2"
echo "ganti juga ip di resolv.conf"
sleep 10s

sudo cp -r nao /var/www
sudo cp domain  /etc/bind/domain
sudo cp ip /etc/bind/ip
sudo rm /etc/bind/named.conf.default-zones
sudo cp named.conf.default-zones /etc/bind/
sudo rm /etc/resolv.conf
sudo cp resolv.conf /etc
sudo service named restart

echo "install apache2.."
sudo apt-get install apache2

echo "stop nginx.."
sudo service nginx stop

echo "install mariadb.."
sudo apt-get install mariadb-server -y

echo "install php..."
sudo apt-get install php php-zip php-intl php-curl php-mbstring php-mysql unzip -y

echo "setting phpmyadmin.."
sudo cp -r nao/phpmyadmin /var/www/nao

echo "setting ftp filemanager"
sudo cp -r nao/mftp /var/www/nao

echo "atur2 dns"

sudo a2dissite 000-default.conf
sudo cp nao.net.conf /etc/apache2/sites-available/
sudo cp pma.nao.net.conf /etc/apache2/sites-available/
sudo cp file.nao.net.conf /etc/apache2/sites-available/

sudo a2ensite nao.net.conf
sudo a2ensite pma.nao.net.conf
sudo a2ensite file.nao.net.conf
sudo service apache2 restart

echo "Install ftp..."
sudo apt-get install vsftpd

sudo rm /etc/vsftpd.conf
sudo cp vsftpd.conf /etc/
sudo systemctl start vsfptd

echo ""

echo "end.."
