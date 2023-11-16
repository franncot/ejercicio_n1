#!/bin/bash

#Variables
red="\e[0;91m"
blue="\e[0;94m"
expand_bg="\e[K"
blue_bg="\e[0;104m${expand_bg}"
red_bg="\e[0;101m${expand_bg}"
green_bg="\e[0;102m${expand_bg}"
green="\e[0;92m"
white="\e[0;97m"
bold="\e[1m"
uline="\e[4m"
reset="\e[0m"
REPO="bootcamp-devops-2023"



#Priviledges
if [ "$EUID" -ne 0 ]; then
    echo -e "${red}${bold}Este script requiere priviledgios de administrador para ser ejecutado. Por favor usa Sudo o Root.${reset}"
    exit 1
fi



# STAGE 1
components=("apache2" "mariadb-server" "php" "git" "libapache2-mod-php" "php-mysql" "php-mbstring" "php-zip" "php-gd" "php-json" "php-curl" )

# Loop through the components array and check/install each one
for component in "${components[@]}"; do
    if dpkg -s "$component" >/dev/null 2>&1; then
        echo -e "${green}${bold} $component ya esta instalado.${reset}"
    else
        echo -e "${red}${bold} Instalando $component .${reset}"
        sudo apt update >/dev/null 2>&1
        sudo apt install "$component" -y >/dev/null 2>&1
		
    fi
done


# Verificar y activar los servicios
services=("apache2" "mariadb")
for service in "${services[@]}"; do
    # Verificar si el servicio está corriendo
    if ! systemctl is-active --quiet "$service"; then
        echo -e "${red}${bold}$service no está en ejecución. Iniciando...${reset}"
        sudo systemctl start "$service" >/dev/null 2>&1
    else
        echo -e "${green}${bold}$service ya está en ejecución.${reset}"
    fi

    # Habilitar el servicio para iniciar en el arranque
    if ! systemctl is-enabled --quiet "$service"; then
        echo -e "${red}${bold}Habilitando $service para iniciar en el arranque.${reset}"
        sudo systemctl enable "$service" >/dev/null 2>&1
    else
         echo -e "${green}${bold}$service ya está configurado para iniciar en el arranque.${reset}"
    fi
done


# Instalacion del repo

if [ -d "$REPO/.git" ]; then
     echo -e "${green}${bold} El repositorio ya existe, realizando git pull...${reset}"
    cd "$REPO_DIR" || exit
else
    echo -e "${red}${bold}Clonando el repositorio, por favor espera!${reset}"
    git clone -b clase2-linux-bash --single-branch https://github.com/roxsross/$REPO.git >/dev/null 2>&1
	cp -r $REPO/app-295devops-travel/* /var/www/html
	echo -e "${green}${bold} Repo clonado y direccionado al folder html${reset}"
fi


# Comando SQL para verificar la existencia de la base de datos
database_check=$(mysql -e "SHOW DATABASES LIKE 'devopstravel'")

# Verificar si la base de datos existe
if [ -z "$database_check" ]; then
    # La base de datos no existe, procede con la creación
    mysql -e "
    CREATE DATABASE devopstravel;
    CREATE USER 'codeuser'@'localhost' IDENTIFIED BY 'codepass';
    GRANT ALL PRIVILEGES ON *.* TO 'codeuser'@'localhost';
    FLUSH PRIVILEGES;"
    mysql < /var/www/html/database/devopstravel.sql >/dev/null 2>&1
else
    echo -e "${green}${bold}La base de datos 'devopstravel' ya existe, y las bases ya tienen datos.${reset}"
fi

sleep 2
mysql < $REPO/app-295devops-travel/database/devopstravel.sql >/dev/null 2>&1

#Modify PHP 
sed -i "s/DirectoryIndex index.html index.cgi index.pl index.php index.xhtml index.htm/DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm/g" /etc/apache2/mods-enabled/dir.conf
sed -i 's/""/"codepass"/g' /var/www/html/config.php

sudo systemctl reload apache2 >/dev/null 2>&1


#Repo ejercicio
if [ -d "ejercicio_n1/.git" ]; then
     echo -e "${green}${bold} El repositorio ya existe...${reset}"
    cd ejercicio_n1 || exit 
else
    git clone https://github.com/franncot/ejercicio_n1.git >/dev/null 2>&1
    cd ejercicio_n1 || exit 
fi

#Notificacion
DISCORD="https://discord.com/api/webhooks/1169002249939329156/7MOorDwzym-yBUs3gp0k5q7HyA42M5eYjfjpZgEwmAx1vVVcLgnlSh4TmtqZqCtbupov"

# Obtiene el nombre del repositorio
REPO_NAME="ejercicio_n1"
# Obtiene la URL remota del repositorio
REPO_URL="https://github.com/franncot/ejercicio_n1.git"
WEB_URL="http://ec2-54-152-223-94.compute-1.amazonaws.com/index.php"
# Realiza una solicitud HTTP GET a la URL
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$WEB_URL")

# Verifica si la respuesta es 200 OK (puedes ajustar esto según tus necesidades)
if [[ "$HTTP_STATUS" == "200" ]]; then
  # Obtén información del repositorio
    DEPLOYMENT_INFO2="Despliegue del repositorio $REPO_NAME: "
    DEPLOYMENT_INFO="La página web $WEB_URL está en línea."
    GRUPO="Equipo10"
    COMMIT="Commit: $(git rev-parse --short HEAD)"
    AUTHOR="Autor: $(git log -1 --pretty=format:'%an')"
    DESCRIPTION="Descripción: $(git log -1 --pretty=format:'%s')"
else
  DEPLOYMENT_INFO="La página web $WEB_URL no está en línea."
fi

# Obtén información del repositorio


# Construye el mensaje
MESSAGE="$AUTHOR\n$COMMIT\n$DESCRIPTION\n$GRUPO\n$DEPLOYMENT_INFO"

# Envía el mensaje a Discord utilizando la API de Discord
curl -X POST -H "Content-Type: application/json" \
     -d '{
       "content": "'"${MESSAGE}"'"
     }' "$DISCORD" 