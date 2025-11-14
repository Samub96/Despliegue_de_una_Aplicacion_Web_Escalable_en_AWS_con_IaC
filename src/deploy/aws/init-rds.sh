#!/bin/bash
# Script para inicializar RDS con datos iniciales
# Se ejecuta después del despliegue para configurar la base de datos

DB_HOST=${1:-"localhost"}
DB_USER=${2:-"admin"}
DB_PASSWORD=${3:-""}
DB_NAME=${4:-"ecom_db"}

echo "🗄️  Inicializando base de datos en $DB_HOST..."

# Script SQL para crear la estructura e insertar datos iniciales
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" <<SQL_SCRIPT
-- Crear tablas si no existen
CREATE TABLE IF NOT EXISTS Products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    image VARCHAR(500),
    stock INT DEFAULT 0,
    category VARCHAR(100),
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS Users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS Carts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    userId INT,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (userId) REFERENCES Users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS CartItems (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cartId INT,
    productId INT,
    quantity INT DEFAULT 1,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (cartId) REFERENCES Carts(id) ON DELETE CASCADE,
    FOREIGN KEY (productId) REFERENCES Products(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    userId INT,
    total DECIMAL(10,2),
    status VARCHAR(50) DEFAULT 'pending',
    shippingAddress TEXT,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (userId) REFERENCES Users(id) ON DELETE CASCADE
);

-- Insertar productos iniciales solo si la tabla está vacía
INSERT INTO Products (name, description, price, image, stock, category)
SELECT * FROM (
    SELECT 'Laptop Gaming', 'Laptop para gaming de alta performance', 1299.99, '/images/laptop-gaming.jpg', 10, 'Electronics'
    UNION ALL
    SELECT 'Smartphone Pro', 'Teléfono inteligente última generación', 899.99, '/images/smartphone-pro.jpg', 25, 'Electronics'  
    UNION ALL
    SELECT 'Auriculares Bluetooth', 'Auriculares inalámbricos con cancelación de ruido', 199.99, '/images/headphones.jpg', 50, 'Electronics'
    UNION ALL
    SELECT 'Camiseta Deportiva', 'Camiseta deportiva transpirable', 29.99, '/images/sport-tshirt.jpg', 100, 'Clothing'
    UNION ALL
    SELECT 'Zapatillas Running', 'Zapatillas para correr profesionales', 149.99, '/images/running-shoes.jpg', 30, 'Clothing'
) AS tmp
WHERE NOT EXISTS (SELECT 1 FROM Products LIMIT 1);

SQL_SCRIPT

if [ $? -eq 0 ]; then
    echo "✅ Base de datos inicializada correctamente"
else
    echo "❌ Error al inicializar la base de datos"
    exit 1
fi