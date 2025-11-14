#!/bin/bash
# User-data script corregido para debugging

set -ex
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "🚀 INICIANDO INSTALACIÓN DE APLICACIÓN DOCKERIZADA"
echo "Timestamp: $(date)"

# Actualizar sistema
echo "📦 Actualizando sistema..."
yum update -y

# Instalar Docker
echo "🐳 Instalando Docker..."
amazon-linux-extras install docker -y
systemctl enable docker
systemctl start docker
usermod -a -G docker ec2-user

# Verificar Docker
docker --version
systemctl status docker --no-pager

# Instalar Docker Compose
echo "🔧 Instalando Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Verificar Docker Compose
/usr/local/bin/docker-compose --version

# Instalar herramientas
echo "🛠️ Instalando herramientas adicionales..."
yum install -y git curl wget

HOME_DIR=/home/ec2-user
REPO_DIR=$HOME_DIR/app

# Clonar repositorio
echo "📥 Clonando repositorio..."
if [ ! -d "$REPO_DIR" ]; then
    cd $HOME_DIR
    sudo -u ec2-user git clone https://github.com/Samub96/Despliegue_de_una_Aplicacion_Web_Escalable_en_AWS_con_IaC.git app || {
        echo "❌ Error clonando repositorio"
        exit 1
    }
    chown -R ec2-user:ec2-user $REPO_DIR
else
    cd $REPO_DIR
    sudo -u ec2-user git pull || echo "⚠️ Warning: git pull failed, continuing..."
fi

# Crear archivo de configuración
echo "⚙️ Creando configuración..."
cd $REPO_DIR
cat > .env <<ENV_FILE
DB_HOST=${DBEndpoint}
DB_NAME=${DBName}
DB_USER=${DBUser}
DB_PASSWORD=${DBPassword}
JWT_SECRET=$(openssl rand -base64 32)
NODE_ENV=production
PORT=8080
ENV_FILE
chown ec2-user:ec2-user .env

# Crear docker-compose para producción AWS
echo "📄 Creando docker-compose de producción..."
cat > docker-compose.aws.yml <<DOCKER_COMPOSE
version: '3.8'
services:
  backend:
    build:
      context: ./src/backend
      dockerfile: Dockerfile
    container_name: ecommerce_backend_aws
    restart: always
    environment:
      - DB_HOST=${DBEndpoint}
      - DB_NAME=${DBName}
      - DB_USER=${DBUser}
      - DB_PASSWORD=${DBPassword}
      - DB_DIALECT=mysql
      - JWT_SECRET=$(openssl rand -base64 32)
      - PORT=8080
      - NODE_ENV=production
    ports:
      - "8080:8080"
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8080/api/health"]
      timeout: 10s
      retries: 5
      interval: 30s
      start_period: 60s
    networks:
      - app-network

  frontend:
    build:
      context: ./src/frontend
      dockerfile: Dockerfile
    container_name: ecommerce_frontend_aws
    restart: always
    ports:
      - "80:80"
    depends_on:
      backend:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:80/health"]
      timeout: 10s
      retries: 3
      interval: 30s
      start_period: 30s
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
DOCKER_COMPOSE
chown ec2-user:ec2-user docker-compose.aws.yml

# Construir e iniciar aplicación
echo "🏗️ Construyendo e iniciando aplicación..."
cd $REPO_DIR

# Dar tiempo para que docker se estabilice
sleep 10

echo "🔨 Ejecutando docker-compose build..."
sudo -u ec2-user /usr/local/bin/docker-compose -f docker-compose.aws.yml build --no-cache || {
    echo "❌ Error en docker build"
    exit 1
}

echo "🚀 Ejecutando docker-compose up..."
sudo -u ec2-user /usr/local/bin/docker-compose -f docker-compose.aws.yml up -d || {
    echo "❌ Error en docker up"
    exit 1
}

# Esperar y verificar
echo "⏳ Esperando que los servicios se estabilicen..."
sleep 60

# Verificar estado
echo "📊 Verificando estado de contenedores..."
sudo -u ec2-user /usr/local/bin/docker-compose -f docker-compose.aws.yml ps

# Probar health checks
echo "🏥 Probando health checks..."
for i in {1..10}; do
    echo "Intento $i de health check..."
    
    # Probar backend
    if curl -s --max-time 5 http://localhost:8080/api/health; then
        echo "✅ Backend health OK"
        break
    else
        echo "⚠️ Backend health falló, reintentando en 30s..."
        sleep 30
    fi
done

for i in {1..10}; do
    echo "Intento $i de frontend health check..."
    
    # Probar frontend
    if curl -s --max-time 5 http://localhost:80/health; then
        echo "✅ Frontend health OK"
        break
    else
        echo "⚠️ Frontend health falló, reintentando en 30s..."
        sleep 30
    fi
done

# Configurar servicio systemd
echo "🔧 Configurando servicio systemd..."
cat > /etc/systemd/system/ecommerce-app.service <<SERVICE_FILE
[Unit]
Description=E-commerce Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$REPO_DIR
ExecStart=/usr/local/bin/docker-compose -f docker-compose.aws.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.aws.yml down
TimeoutStartSec=300
User=ec2-user
Restart=on-failure

[Install]
WantedBy=multi-user.target
SERVICE_FILE

systemctl enable ecommerce-app.service

# Logs finales
echo "📋 Logs de contenedores:"
sudo -u ec2-user /usr/local/bin/docker-compose -f docker-compose.aws.yml logs

echo "🎉 Instalación completada!"
echo "Timestamp: $(date)"