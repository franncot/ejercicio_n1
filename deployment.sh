#!/bin/bash

# Priviledges
if [ "$EUID" -ne 0 ]; then
    echo "Este script requiere priviledgios de administrador para ser ejecutado. Por favor usa Sudo o Root."
    exit 1
fi

# Array
components=("apache2" "mariadb-server" "php" "git" "libapache2-mod-php" "php-mysql" "php-mbstring" "php-zip" "php-gd" "php-json" "php-curl" )

# Loop through the components array and check/install each one
for component in "${components[@]}"; do
    if ! command -v "$component" &>/dev/null; then
        echo "$component is not installed. Installing..."
        sudo apt update >/dev/null 2>&1
        sudo apt install "$component" -y >/dev/null 2>&1
    else
        echo "$component is already installed."
    fi
done

# Restart Apache after installation/verification
sudo systemctl start apache2 >/dev/null 2>&1
sudo systemctl enable apache2 >/dev/null 2>&1
sudo systemctl status apache2 >/dev/null 2>&1

MYSQLPASS = "0n3Two3"
# Check if MariaDB root password is set
if ! sudo mysqladmin -u root password -s status &>/dev/null; then
    # Set MariaDB root password if not set
    echo "Setting up MariaDB root password..."
    sudo mysqladmin -u root password $MYSQLPASS
fi

# Create a new database and user
DB_NAME="devopstravel"
DB_USER="codeuser"
DB_PASSWORD="codepass"

echo "Creating MariaDB database: $DB_NAME and user: $DB_USER..."
sudo mysql -u root -p"$MYSQLPASS" <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS $DB_NAME;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

sleep 2

REPO = "bootcamp-devops-2023"

# Check if the directory exists

if [ -d "$REPO/.git" ]; then
    echo "El repositorio ya existe, realizando git pull..."
    cd "$REPO_DIR" || exit
    git pull origin master
else
    echo "Cloning the repository wait a few minutes pls!"
    git clone -b clase2-linux-bash --single-branch https://github.com/roxsross/$REPO.git >/dev/null 2>&1
	cp -r $REPO/app-295devops-travel/* /var/www/html
	mysql < $REPO/app-295devops-travel/database/devopstravel.sql >/dev/null 2>&1
	echo "Repo clone Completed!"
fi


#Modify PHP 
#sed -i "s/DirectoryIndex index.html index.php/DirectoryIndex index.php index.html/g" /etc/apache2/mods-enabled/dir.conf
#sudo systemctl reload apache2 >/dev/null 2>&1
