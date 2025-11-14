#!/bin/bash
set -ex
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "🚀 INICIANDO INSTALACIÓN - $(date)"

# Actualizar sistema
yum update -y

# Instalar Docker
amazon-linux-extras install docker -y
systemctl enable docker
systemctl start docker
usermod -a -G docker ec2-user

# Instalar Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Verificar instalaciones
docker --version
docker-compose --version

# Instalar herramientas
yum install -y git curl wget

HOME_DIR=/home/ec2-user
REPO_DIR=$HOME_DIR/app

# Clonar repositorio
if [ ! -d "$REPO_DIR" ]; then
    cd $HOME_DIR
    sudo -u ec2-user git clone https://github.com/Samub96/Despliegue_de_una_Aplicacion_Web_Escalable_en_AWS_con_IaC.git app
    chown -R ec2-user:ec2-user $REPO_DIR
fi

cd $REPO_DIR

# Variables de la base de datos RDS (serán reemplazadas por CloudFormation)
DB_ENDPOINT="DB_ENDPOINT_PLACEHOLDER"
DB_NAME="ecommerce_db"
DB_USER="appuser"
DB_PASSWORD="ProjFinal#2025"

# Crear docker-compose para AWS
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
      - DB_HOST=$DB_ENDPOINT
      - DB_NAME=$DB_NAME
      - DB_USER=$DB_USER
      - DB_PASSWORD=$DB_PASSWORD
      - DB_DIALECT=mysql
      - JWT_SECRET=supersecretkey123
      - PORT=8080
      - NODE_ENV=production
    ports:
      - "8080:8080"
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8080/api/health"]
      timeout: 10s
      retries: 10
      interval: 30s
      start_period: 120s
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
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:80/health"]
      timeout: 10s
      retries: 5
      interval: 30s
      start_period: 60s
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
DOCKER_COMPOSE

chown ec2-user:ec2-user docker-compose.aws.yml

# Construir e iniciar aplicación
echo "🏗️ Construyendo aplicación - $(date)"
sudo -u ec2-user docker-compose -f docker-compose.aws.yml build --no-cache

echo "🚀 Iniciando aplicación - $(date)"
sudo -u ec2-user docker-compose -f docker-compose.aws.yml up -d

# Esperar y verificar
sleep 60
echo "📊 Estado de contenedores:"
sudo -u ec2-user docker-compose -f docker-compose.aws.yml ps

echo "🏥 Verificando health checks:"
for i in {1..20}; do
    if curl -s --max-time 5 http://localhost:80/health | grep -q "healthy"; then
        echo "✅ Frontend health OK"
        break
    else
        echo "⏳ Esperando frontend... intento $i/20"
        sleep 15
    fi
done

# Configurar servicio systemd
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
TimeoutStartSec=600
User=ec2-user

[Install]
WantedBy=multi-user.target
SERVICE_FILE

systemctl enable ecommerce-app.service

echo "🎉 Instalación completada - $(date)"