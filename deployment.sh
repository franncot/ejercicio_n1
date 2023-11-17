#!/bin/bash

#Variables de colores
red="\e[0;91m"
green="\e[0;92m"
bold="\e[1m"
reset="\e[0m"
REPO="bootcamp-devops-2023"


#Priviledges
if [ "$EUID" -ne 0 ]; then
    echo -e "${red}${bold}Este script requiere priviledgios de administrador para ser ejecutado. Por favor usa Sudo o Root.${reset}"
    exit 1
fi

#Only one update
sudo apt update >/dev/null 2>&1

# Installation of components
components=("apache2" "mariadb-server" "php" "git" "libapache2-mod-php" "php-mysql" "php-mbstring" "php-zip" "php-gd" "php-json" "php-curl" )

# Loop through the components array and check/install each one
for component in "${components[@]}"; do
    if dpkg -s "$component" >/dev/null 2>&1; then
        echo -e "${green}${bold}$component ya esta instalado.${reset}"
    else
        echo -e "${red}${bold}Instalando $component .${reset}"
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


# Cloning Repo DevOps Travel

if [ -d "$REPO/.git" ]; then
     echo -e "${green}${bold}El repositorio ya existe, realizando git pull...${reset}"
     cd $REPO
     git pull >/dev/null 2>&1
     cp -r $REPO/app-295devops-travel/* /var/www/html
	 echo -e "${green}${bold}Pull completado, datos copiados a la carpeta html${reset}"
else
    echo -e "${red}${bold}Clonando el repositorio, por favor espera!${reset}"
    git clone -b clase2-linux-bash --single-branch https://github.com/roxsross/$REPO.git >/dev/null 2>&1
	cp -r $REPO/app-295devops-travel/* /var/www/html
	echo -e "${green}${bold}Repo clonado y direccionado al folder html${reset}"
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
    echo -e "${green}${bold}La base de datos 'devopstravel' ya existe y tiene data, no se necesita modificar nada mas.${reset}"
fi

#Modify PHP configurations
sed -i "s/DirectoryIndex index.html index.cgi index.pl index.php index.xhtml index.htm/DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm/g" /etc/apache2/mods-enabled/dir.conf
sed -i 's/""/"codepass"/g' /var/www/html/config.php

#Reload to get changes
sudo systemctl reload apache2 >/dev/null 2>&1


#Repo ejercicio para notificaciones
if [ -d "ejercicio_n1/.git" ]; then
     echo -e "${green}${bold}El repositorio ya existe...${reset}"
    cd ejercicio_n1 || exit 
else
    git clone https://github.com/franncot/ejercicio_n1.git >/dev/null 2>&1
    cd ejercicio_n1 || exit 
fi

#Notificacion Discord
DISCORD="https://discord.com/api/webhooks/1169002249939329156/7MOorDwzym-yBUs3gp0k5q7HyA42M5eYjfjpZgEwmAx1vVVcLgnlSh4TmtqZqCtbupov"
WEB_URL="http://localhost/index.php"

# Realiza prueba de hhtp code
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$WEB_URL")

# Verifica si la pagina responde correctamente
if [[ "$HTTP_STATUS" == "200" ]]; then
    DEPLOYMENT_INFO="295DevOpsTravel - está en línea."
    GRUPO="Equipo10"
    COMMIT="Commit: $(git rev-parse --short HEAD)"
    AUTHOR="Autor: $(git log -1 --pretty=format:'%an')"
    DESCRIPTION="Descripción: $(git log -1 --pretty=format:'%s')"
    MESSAGE="$AUTHOR\n$COMMIT\n$DESCRIPTION\n$GRUPO\n$DEPLOYMENT_INFO"
    # Envía el mensaje a Discord utilizando la API de Discord
    curl -X POST -H "Content-Type: application/json" \
         -d '{
           "content": "'"${MESSAGE}"'"
         }' "$DISCORD" 
else
    DEPLOYMENT_INFO="DevOpsTravel no está en línea. Por favor revisa el servidor."
    GRUPO="Equipo10"
    COMMIT="Commit: $(git rev-parse --short HEAD)"
    AUTHOR="Autor: $(git log -1 --pretty=format:'%an')"
    DESCRIPTION="Descripción: $(git log -1 --pretty=format:'%s')"
    MESSAGE="$AUTHOR\n$COMMIT\n$DESCRIPTION\n$GRUPO\n$DEPLOYMENT_INFO"
    # Envía el mensaje a Discord utilizando la API de Discord
    curl -X POST -H "Content-Type: application/json" \
         -d '{
           "content": "'"${MESSAGE}"'"
         }' "$DISCORD"
fi

