#!/bin/bash

# Database credentials
DB_HOST="localhost"
DB_USER="root"
DB_PASS="admine123"
DB_NAME="naohosting"
TABLE_NAME="nao_user"
COUNT_FILE="user_count.txt"
DOMAIN="nao.net"
BIND_ZONE_FILE="/etc/bind/domain"
APACHE_SITES_AVAILABLE="/etc/apache2/sites-available"
APACHE_SITES_ENABLED="/etc/apache2/sites-enabled"

# Fungsi untuk menghitung jumlah user yang telah terdaftar pada database
get_user_count() {
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -se "SELECT COUNT(*) FROM $TABLE_NAME;"
}

# Fungsi untuk mendapatkan data username dan password user yang baru daftar
get_new_usernames() {
    local last_count=$1
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -se "SELECT username, password FROM $TABLE_NAME ORDER BY id DESC LIMIT $((current_count - last_count));"
}

# Fungsi untuk mendaftarkan subdomain di BIND
create_dns_entry() {
    local username=$1
    echo "${username}    IN      A      192.168.97.73" >> "$BIND_ZONE_FILE" 
    sudo service named restart
}

# Funsi untuk konfigurasi host di Apache 
create_apache_vhost() {
    local username=$1
    local config_file="${APACHE_SITES_AVAILABLE}/${username}.${DOMAIN}.conf"

    cat <<EOF > "$config_file host apache"
<VirtualHost *:80>
    ServerName ${username}.${DOMAIN}
    DocumentRoot /var/www/html/${username}
    ErrorLog \${APACHE_LOG_DIR}/${username}_error.log
    CustomLog \${APACHE_LOG_DIR}/${username}_access.log combined

    <Directory /var/www/html/${username}>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

# Membuat directory untuk user
    sudo mkdir -p /var/www/html/${username}
    sudo chown -R www-data:www-data /var/www/html/${username}
    sudo echo "<html><body><h1>Welcome to ${username}.${DOMAIN}</h1></body></html>" > /var/www/html/${username}/index.html

	sudo ln -s "${config_file}" "${APACHE_SITES_ENABLED}/${username}.${DOMAIN}.conf"

    sudo a2ensite "${username}.${DOMAIN}.conf"
    sudo service apache2 restart
}

# Fungsi create user baru untuk akses FTP
create_ftp_user() {
    local username=$1
    local password=$2

    # Buat user baru beserta direktori homenya di /var/www/html/username
    sudo useradd -m -d /var/www/html/${username} -s /usr/sbin/nologin "$username"
    sudo echo "${username}:${password}" | chpasswd

    # Set ownership dan permission directory
    sudo chown -R ${username}:${username} /var/www/html/${username}
    sudo chmod -R 755 /var/www/html/${username}

    # Tampilkan kredensi user yang baru dibuat
    # Untuk login ftp (password dan username)
    echo "FTP user created:"
    echo "Username: ${username}"
    echo "Password: ${password}"
}

# Fungsi untuk membuat database MySQL user
create_mysql_db_user() {
    local username=$1
    local password=$2
    local db_name="${username}_db"

    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -se "CREATE DATABASE $db_name;"
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -se "CREATE USER '${username}'@'localhost' IDENTIFIED BY '${password}';"
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -se "GRANT ALL PRIVILEGES ON ${db_name}.* TO '${username}'@'localhost';"
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -se "FLUSH PRIVILEGES;"

	# Menampilan kredensi user yang telah dibuatkan database
    echo "MySQL database and user created:"
    echo "Database: ${db_name}"
    echo "Username: ${username}"
    echo "Password: ${password}"
}

# Cek count_user.txt jika tidak ada buat filenya
# digunakan untuk menampung nilai jumlah user yang ada pada database 
if [ ! -f "$COUNT_FILE" ]; then
    echo "0" > "$COUNT_FILE"
fi

# Get jumlah user terbaru (setelah user baru terdaftar)
last_count=$(cat "$COUNT_FILE")

# Get jumlah user saat ini 
current_count=$(get_user_count)

# Cek apakah user baru sudah dibuat
# Jika belum panggil fungsi untuk daftarkan subdomain, buat akun dan ftp, juga mysql database user baru
if [ "$current_count" -gt "$last_count" ]; then
    echo "new data added"
    new_users=$(get_new_usernames "$last_count")
    # Cek password user baru
    while IFS=$'\t' read -r username password; do
        echo "Configuring DNS, Apache, and FTP for ${username}.${DOMAIN}"
        echo "${username}.${DOMAIN} Sedang diprosese..."
        sleep 5s
        create_dns_entry "$username"
        create_apache_vhost "$username"
        create_ftp_user "$username" "$password"
        create_mysql_db_user "$username" "$password"
    done <<< "$new_users"
    echo "$current_count" > "$COUNT_FILE"
else 
    sleep 5s
fi

echo $user
