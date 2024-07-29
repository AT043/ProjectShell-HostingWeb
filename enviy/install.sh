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
sudo mv /etc/bind/named.conf.default-zones /etc/bind/named.conf.default-zones-cad
sudo cp named.conf.default-zones /etc/bind/
sudo cp /etc/resolv.conf /etc/resolv.conf-cad
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

echo "atur2 dns"

sudo a2dissite 000-default.conf
sudo cp nao.net.conf /etc/apache2/sites-available/
sudo cp pma.nao.net.conf /etc/apache2/sites-available/
sudo cp file.nao.net.conf /etc/apache2/sites-available/

sudo ln -s /etc/apache2/sites-available/nao.net.conf /etc/apache2/sites-enabled/
sudo ln -s /etc/apache2/sites-available/file.nao.net.conf /etc/apache2/sites-enabled/
sudo ln -s /etc/apache2/sites-available/pma.nao.net.conf /etc/apache2/sites-enabled/

sudo a2ensite nao.net.conf
sudo a2ensite pma.nao.net.conf
sudo a2ensite file.nao.net.conf
sudo service apache2 restart

echo "Install ftp..."
sudo apt-get install vsftpd

sudo rm /etc/vsftpd.conf
sudo cp vsftpd.conf /etc/
sudo systemctl start vsfptd

sudo service named restart
sudo service apache2 restart

echo "Import database..."
mysql -h "localhost" -u "root" -p"" -se "CREATE DATABASE naohosting;"
mysql -u root -p naohosting < naohosting.sql 

echo "end.."
