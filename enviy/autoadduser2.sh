#!/bin/bash

# Database credentials
DB_HOST="localhost"
DB_USER="root"
DB_PASS="admine123"
DB_NAME="naohosting"
TABLE_NAME="nao_user"
LAST_USERNAMES_FILE="last_usernames.txt"
DOMAIN="nao.net"
BIND_ZONE_FILE="/etc/bind/domain"
APACHE_SITES_AVAILABLE="/etc/apache2/sites-available"
APACHE_SITES_ENABLED="/etc/apache2/sites-enabled"
FTP_HOME_DIR="/var/www/nao"

while true; do
  # Fungsi untuk ambil semua username di database
  get_all_usernames() {
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -se "SELECT username FROM $TABLE_NAME;"
  }

  #Fungsi untuk Create entri DNS di BIND9
  create_dns_entry() {
    local username=$1
    echo "${username}    IN      A      192.168.79.7" >> "$BIND_ZONE_FILE"
    sudo service named restart
  }

  #Fungsi untuk menghapus entri DNS dari bind9
  remove_dns_entry() {
    local username=$1
    sed -i "/${username}    IN      A      192.168.79.7/d" "$BIND_ZONE_FILE"
    sudo service named restart
  }
  
    #Fungsi untuk add konfigurasi apache virtual host
  create_apache_vhost() {
    local username=$1
    local config_file="${APACHE_SITES_AVAILABLE}/${username}.${DOMAIN}.conf"

    cat <<EOF > "$config_file"
<VirtualHost *:80>
    ServerName ${username}.${DOMAIN}
    DocumentRoot /var/www/nao/${username}
    ErrorLog \${APACHE_LOG_DIR}/${username}_error.log
    CustomLog \${APACHE_LOG_DIR}/${username}_access.log combined

    <Directory /var/www/nao/${username}>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

    #Buat Direktori untuk web user
    sudo mkdir -p /var/www/nao/${username}
    sudo echo "<html><header><title>${username}.${DOMAIN}</title></header><body><h1>Welcome to ${username}.${DOMAIN}</h1><hr></body></html>" > /var/www/nao/${username}/index.html

    sudo ln -s "${config_file}" "${APACHE_SITES_ENABLED}/${username}.${DOMAIN}.conf"

    sudo a2ensite "${username}.${DOMAIN}.conf"
    sudo service apache2 restart
  }

  #Fungsi remove konfigurasi apache user
  remove_apache_vhost() {
    local username=$1
    local config_file="${APACHE_SITES_AVAILABLE}/${username}.${DOMAIN}.conf"

    sudo a2dissite "${username}.${DOMAIN}.conf"
    sudo rm -f "${config_file}"
    sudo rm -f "${APACHE_SITES_ENABLED}/${username}.${DOMAIN}.conf"
    sudo rm -rf "/var/www/nao/${username}"
    sudo service apache2 restart
  }

  #Fungsi untuk add user baru ke server untuk akses FTP dan direktori
  create_ftp_user() {
    local username=$1
    local password=$2

    #Buat user baru di server dengan direktori home di /var/www/nao/username
    sudo useradd -m -d /var/www/nao/${username} -s /usr/sbin/nologin "$username"
    echo "${username}:${password}" | sudo chpasswd

    #Set permission dan ownership direktory untuk user
    sudo chown -R ${username}:${username} /var/www/nao/${username}
    sudo chmod -R 755 /var/www/nao/${username}
	
    
    #Tampilkan hasil create user (password dan usernamenya) di server
    echo "Direktori user dan FTP berhasil:"
    echo "Username: ${username}"
    echo "Password: ${password}"
    sleep 5s
  }

  #Fungsi buat delete user dan direktori ftpnya
  delete_ftp_user() {
    local username=$1
    sudo userdel -r "$username"
    sudo rm -rf "${FTP_HOME_DIR}/${username}"
  }

  #Fungsi untuk create database MySQL user
  create_mysql_db_user() {
    local username=$1
    local password=$2
    local db_name="${username}_db"

    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -se "CREATE DATABASE $db_name;"
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -se "CREATE USER '${username}'@'localhost' IDENTIFIED BY '${password}';"
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -se "GRANT ALL PRIVILEGES ON ${db_name}.* TO '${username}'@'localhost';"
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -se "FLUSH PRIVILEGES;"

    #Tampilkan hasil create db mysql untuk user
    echo "db MySQL untuk user berhasil dibuat..."
    echo "Database: ${db_name}"
    echo "Username: ${username}"
    echo "Password: ${password}"
    sleep 5s
  }

  #Fungsi untuk hapus database mysql user
  delete_mysql_db_user() {
    local username=$1
    local db_name="${username}_db"

    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -se "DROP DATABASE IF EXISTS $db_name;"
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -se "DROP USER IF EXISTS '${username}'@'localhost';"
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -se "FLUSH PRIVILEGES;"
  }

  
  #Buat file last_username untuk tampung data username jika blm ada
  if [ ! -f "$LAST_USERNAMES_FILE" ]; then
    touch "$LAST_USERNAMES_FILE"
  fi

  #Get data username_terakhir dari db dan masukkan ke temp file
  current_usernames=$(get_all_usernames)
  current_usernames_file=$(mktemp)
  echo "$current_usernames" > "$current_usernames_file"

  #Cek last_username
  if [ -s "$LAST_USERNAMES_FILE" ]; then
    readarray -t last_usernames < "$LAST_USERNAMES_FILE"
  else
    last_usernames=()
  fi

  #Cek apakah ada user baru
  new_users=()
  for username in $current_usernames; do
    if ! [[ " ${last_usernames[@]} " =~ " $username " ]]; then
      new_users+=("$username")
    fi
  done

  #Tambah user
  #Kondisi jika ada user baru jalankan fungsi dns_entry; apache_vhost; ftp_user; dan mysql_db_user
  if [ ${#new_users[@]} -gt 0 ]; then
    for username in "${new_users[@]}"; do
      password=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -se "SELECT password FROM $TABLE_NAME WHERE username='$username';")
      echo "DNS, Apache, FTP, and MySQL ${username}.${DOMAIN} Sedang diproses..."
      sleep 5s
      create_dns_entry "$username"
      create_apache_vhost "$username"
      create_ftp_user "$username" "$password"
      create_mysql_db_user "$username" "$password"
    done
    #Update data username dengan data terbaru
    echo "$current_usernames" | tr ' ' '\n' > "$LAST_USERNAMES_FILE"
  else
    echo "tidak ada user baru"
    sleep 5s
  fi

  #cari username mana yang tlah dihapus dari db
  deleted_users=()
  for username in "${last_usernames[@]}"; do
    if ! grep -q "$username" "$current_usernames_file"; then
      deleted_users+=("$username")
    fi
  done

  #Kondisi jika user dihapus dari database
  #Hapus segala akses beserta direktory, permission, dan konfigurasinya
  if [ ${#deleted_users[@]} -gt 0 ]; then
    for username in "${deleted_users[@]}"; do
      echo "${username} telah dihapus dari database. Menghapus resource..."
      delete_ftp_user "$username"
      delete_mysql_db_user "$username"
      remove_dns_entry "$username"
      remove_apache_vhost "$username"
    done
    echo "$current_usernames" | tr ' ' '\n' > "$LAST_USERNAMES_FILE" 
  else
	sleep 1s
  fi

  rm -f "$current_usernames_file"

  sleep 10s
done
