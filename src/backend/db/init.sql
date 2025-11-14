-- Script de inicialización para MySQL
-- Se ejecuta automáticamente cuando se crea el contenedor por primera vez

-- Crear la base de datos si no existe
CREATE DATABASE IF NOT EXISTS ecom_db;

-- Usar la base de datos
USE ecom_db;

-- Asegurar que el usuario root puede conectarse desde cualquier IP
UPDATE mysql.user SET Host='%' WHERE User='root' AND Host='localhost';

-- Otorgar todos los permisos al usuario root desde cualquier host
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;

-- Asegurar que la contraseña esté configurada correctamente
ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY 'mysql_password';

-- Aplicar los cambios
FLUSH PRIVILEGES;