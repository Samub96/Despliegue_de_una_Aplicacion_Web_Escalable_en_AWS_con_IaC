#!/bin/bash
set -ex
# Log all output to console and file
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "START: userdata $(date -u)"

# Update system
yum update -y

# Install Docker
amazon-linux-extras install docker -y
systemctl enable docker
systemctl start docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Verify installs
docker --version || true
docker-compose --version || true

# Install tools
yum install -y git curl wget

HOME_DIR=/home/ec2-user
REPO_DIR=$HOME_DIR/app

# Clone repository if not present
if [ ! -d "$REPO_DIR" ]; then
  cd $HOME_DIR
  sudo -u ec2-user git clone https://github.com/Samub96/Despliegue_de_una_Aplicacion_Web_Escalable_en_AWS_con_IaC.git app
  chown -R ec2-user:ec2-user $REPO_DIR
fi

cd $REPO_DIR

# Values substituted before creating Launch Configuration
DB_ENDPOINT="DB_ENDPOINT_PLACEHOLDER"
DB_NAME="ecommerce_db"
DB_USER="appuser"
DB_PASSWORD="ProjFinal#2025"

# Create docker-compose file
cat > docker-compose.aws.yml <<'DOCKER_COMPOSE'
version: '3.8'
services:
  backend:
    build:
      context: ./src/backend
      dockerfile: Dockerfile
    container_name: ecommerce_backend_aws
    restart: always
    environment:
      - DB_HOST=${DB_ENDPOINT}
      - DB_NAME=${DB_NAME}
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
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

# Replace variables in docker-compose (simple sed)
sed -i "s|\${DB_ENDPOINT}|$DB_ENDPOINT|g" docker-compose.aws.yml
sed -i "s|\${DB_NAME}|$DB_NAME|g" docker-compose.aws.yml
sed -i "s|\${DB_USER}|$DB_USER|g" docker-compose.aws.yml
sed -i "s|\${DB_PASSWORD}|$DB_PASSWORD|g" docker-compose.aws.yml

chown ec2-user:ec2-user docker-compose.aws.yml

# Build and run
sudo -u ec2-user docker-compose -f docker-compose.aws.yml build
sudo -u ec2-user docker-compose -f docker-compose.aws.yml up -d

# Give some time to start
sleep 30
sudo -u ec2-user docker-compose -f docker-compose.aws.yml ps

# systemd service for persistence
cat > /etc/systemd/system/ecommerce-app.service <<SERVICE_FILE
[Unit]
Description=Ecommerce App Docker Compose
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

echo "END: userdata $(date -u)"