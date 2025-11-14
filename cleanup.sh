#!/bin/bash

echo "🧹 Limpiando completamente el entorno Docker..."

# 1. Parar y eliminar todos los contenedores relacionados
echo "⏹️  Parando contenedores..."
docker compose down -v 2>/dev/null || true

# 2. Eliminar imágenes específicas
echo "🗑️  Eliminando imágenes..."
docker rmi $(docker images "*ecommerce*" -q) 2>/dev/null || true

# 3. Eliminar volúmenes específicos
echo "📦 Eliminando volúmenes..."
docker volume rm despliegue_de_una_aplicacion_web_escalable_en_aws_con_iac_mysql_data 2>/dev/null || true

# 4. Eliminar node_modules del host
echo "🗂️  Eliminando node_modules del host..."
rm -rf /workspaces/Despliegue_de_una_Aplicacion_Web_Escalable_en_AWS_con_IaC/src/backend/node_modules

# 5. Limpiar cache de Docker
echo "🧽 Limpiando cache de Docker..."
docker system prune -f 2>/dev/null || true

echo "✅ Limpieza completada. Ahora ejecuta: docker compose up --build -d"