#!/bin/bash

echo "update repo..."
sudo apt-get update

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

