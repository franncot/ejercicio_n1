# Ejercicio-1 Linux y Automatización

STAGE 1: [Init]

    Instalacion de paquetes en el sistema operativo ubuntu: [apache, php, mariadb, git, curl, etc]
    Validación si esta instalado los paquetes o no , de manera de no reinstalar
    Habilitar y Testear instalación de los paquetes

STAGE 2: [Build]

    Clonar el repositorio de la aplicación
    Validar si el repositorio de la aplicación no existe realizar un git clone. y si existe un git pull
    Mover al directorio donde se guardar los archivos de configuración de apache /var/www/html/
    Testear existencia del codigo de la aplicación
    Ajustar el config de php para que soporte los archivos dinamicos de php agregando index.php
    Testear la compatibilidad -> ejemplo http://localhost/info.php
    Si te muestra resultado de una pantalla informativa php , estariamos funcional para la siguiente etapa.

STAGE 3: [Deploy]

    Es momento de probar la aplicación, recuerda hacer un reload de apache y acceder a la aplicacion DevOps Travel
    Aplicación disponible para el usuario final.

STAGE 4: [Notify]

    El status de la aplicacion si esta respondiendo correctamente o esta fallando debe reportarse via webhook al canal de discord #deploy-bootcamp
    Informacion a mostrar : Author del Commit, Commit, descripcion, grupo y status

