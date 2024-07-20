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
FTP_HOME_DIR="/var/www/html"

while true; do
  # Function to get all current usernames
  get_all_usernames() {
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -se "SELECT username FROM $TABLE_NAME;"
  }

  # Function to get the latest user data (username and password)
  get_new_user_data() {
    local last_usernames=("$@")
    local query="SELECT username, password FROM $TABLE_NAME WHERE username NOT IN ('${last_usernames[*]}');"
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -se "$query"
  }

  # Function to create DNS entry in BIND
  create_dns_entry() {
    local username=$1
    echo "${username}    IN      A      192.168.97.73" >> "$BIND_ZONE_FILE"
    sudo service named restart
  }

  # Function to remove DNS entry from BIND
  remove_dns_entry() {
    local username=$1
    sed -i "/${username}    IN      A      192.168.97.73/d" "$BIND_ZONE_FILE"
    sudo service named restart
  }

  # Function to configure Apache host
  create_apache_vhost() {
    local username=$1
    local config_file="${APACHE_SITES_AVAILABLE}/${username}.${DOMAIN}.conf"

    cat <<EOF > "$config_file"
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

    # Create directory for user
    sudo mkdir -p /var/www/html/${username}
    sudo chown -R www-data:www-data /var/www/html/${username}
    sudo echo "<html><body><h1>Welcome to ${username}.${DOMAIN}</h1></body></html>" > /var/www/html/${username}/index.html

    sudo ln -s "${config_file}" "${APACHE_SITES_ENABLED}/${username}.${DOMAIN}.conf"

    sudo a2ensite "${username}.${DOMAIN}.conf"
    sudo service apache2 restart
  }

  # Function to remove Apache configuration
  remove_apache_vhost() {
    local username=$1
    local config_file="${APACHE_SITES_AVAILABLE}/${username}.${DOMAIN}.conf"

    sudo a2dissite "${username}.${DOMAIN}.conf"
    sudo rm -f "${config_file}"
    sudo rm -f "${APACHE_SITES_ENABLED}/${username}.${DOMAIN}.conf"
    sudo rm -rf "/var/www/html/${username}"
    sudo service apache2 restart
  }

  # Function to create a system user for FTP access
  create_ftp_user() {
    local username=$1
    local password=$2

    # Create the user with /var/www/html/${username} as home directory
    sudo useradd -m -d /var/www/html/${username} -s /usr/sbin/nologin "$username"
    echo "${username}:${password}" | sudo chpasswd

    # Set ownership and permissions
    sudo chown -R ${username}:${username} /var/www/html/${username}
    sudo chmod -R 755 /var/www/html/${username}

    # Display the created user's credentials (could be logged instead)
    echo "FTP user created:"
    echo "Username: ${username}"
    echo "Password: ${password}"
    sleep 5s
  }

  # Function to delete an FTP user
  delete_ftp_user() {
    local username=$1
    sudo userdel -r "$username"
    sudo rm -rf "${FTP_HOME_DIR}/${username}"
  }

  # Function to create a MySQL database and user
  create_mysql_db_user() {
    local username=$1
    local password=$2
    local db_name="${username}_db"

    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -se "CREATE DATABASE $db_name;"
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -se "CREATE USER '${username}'@'localhost' IDENTIFIED BY '${password}';"
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -se "GRANT ALL PRIVILEGES ON ${db_name}.* TO '${username}'@'localhost';"
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -se "FLUSH PRIVILEGES;"

    # Display the created user's credentials
    echo "MySQL database and user created:"
    echo "Database: ${db_name}"
    echo "Username: ${username}"
    echo "Password: ${password}"
    sleep 5s
  }

  # Function to delete a MySQL user and database
  delete_mysql_db_user() {
    local username=$1
    local db_name="${username}_db"

    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -se "DROP DATABASE IF EXISTS $db_name;"
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -se "DROP USER IF EXISTS '${username}'@'localhost';"
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -se "FLUSH PRIVILEGES;"
  }

  # Initialize count file if it doesn't exist
  if [ ! -f "$LAST_USERNAMES_FILE" ]; then
    touch "$LAST_USERNAMES_FILE"
  fi

  # Get current usernames from database and store them in a temporary file
  current_usernames=$(get_all_usernames)
  current_usernames_file=$(mktemp)
  echo "$current_usernames" > "$current_usernames_file"

  # Read last usernames from file
  if [ -s "$LAST_USERNAMES_FILE" ]; then
    readarray -t last_usernames < "$LAST_USERNAMES_FILE"
  else
    last_usernames=()
  fi

  # Determine new users
  new_users=()
  for username in $current_usernames; do
    if ! [[ " ${last_usernames[@]} " =~ " $username " ]]; then
      new_users+=("$username")
    fi
  done

  # Handle new users
  if [ ${#new_users[@]} -gt 0 ]; then
    for username in "${new_users[@]}"; do
      password=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -se "SELECT password FROM $TABLE_NAME WHERE username='$username';")
      echo "Configuring DNS, Apache, FTP, and MySQL for ${username}.${DOMAIN}"
      echo "${username}.${DOMAIN} Sedang diproses..."
      sleep 5s
      create_dns_entry "$username"
      create_apache_vhost "$username"
      create_ftp_user "$username" "$password"
      create_mysql_db_user "$username" "$password"
    done
    # Update the last known usernames file with the current usernames
    echo "$current_usernames" | tr ' ' '\n' > "$LAST_USERNAMES_FILE"
  else
    echo "no new data"
    sleep 5s
  fi

  # Determine deleted users
  deleted_users=()
  for username in "${last_usernames[@]}"; do
    if ! grep -q "$username" "$current_usernames_file"; then
      deleted_users+=("$username")
    fi
  done

  # Handle deleted users
  if [ ${#deleted_users[@]} -gt 0 ]; then
    for username in "${deleted_users[@]}"; do
      echo "User ${username} has been deleted from the database. Removing associated resources..."
      delete_ftp_user "$username"
      delete_mysql_db_user "$username"
      remove_dns_entry "$username"
      remove_apache_vhost "$username"
    done
  fi

  rm -f "$current_usernames_file"

  sleep 10s
done
