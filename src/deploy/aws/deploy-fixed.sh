#!/bin/bash

# Script maestro para deployar la aplicación con configuración corregida
# 1. Usa docker-compose.yml existente + override para producción  
# 2. Registra instancia EC2 individual al ALB
# 3. Desactiva Auto Scaling Group para evitar conflictos

set -e

echo "🚀 Iniciando deployment con configuración corregida..."

# Paso 1: Desactivar Auto Scaling Group
echo ""
echo "📋 Paso 1: Desactivando Auto Scaling Group..."
chmod +x disable-autoscaling.sh
./disable-autoscaling.sh

# Paso 2: Actualizar ALB
echo ""
echo "📋 Paso 2: Actualizando ALB..."
VPC_STACK="ecommerce-vpc-stack"
ALB_STACK="ecommerce-alb-stack"

VPC_ID=$(aws cloudformation describe-stacks \
  --stack-name $VPC_STACK \
  --query 'Stacks[0].Outputs[?OutputKey==`VpcId`].OutputValue' \
  --output text)

PUBLIC_SUBNETS=$(aws cloudformation describe-stacks \
  --stack-name $VPC_STACK \
  --query 'Stacks[0].Outputs[?OutputKey==`PublicSubnetIds`].OutputValue' \
  --output text)

if aws cloudformation describe-stacks --stack-name $ALB_STACK >/dev/null 2>&1; then
  aws cloudformation update-stack \
    --stack-name $ALB_STACK \
    --template-body file://templates/alb.yaml \
    --parameters \
      ParameterKey=VpcId,ParameterValue=$VPC_ID \
      ParameterKey=PublicSubnetIds,ParameterValue="$PUBLIC_SUBNETS"
  aws cloudformation wait stack-update-complete --stack-name $ALB_STACK || true
fi

echo "✅ ALB actualizado"

# Paso 3: Actualizar EC2 con registro al ALB
echo ""
echo "📋 Paso 3: Actualizando instancia EC2..."
chmod +x update-ec2-stack.sh
./update-ec2-stack.sh

echo ""
echo "🎉 Deployment completado exitosamente!"
echo ""
echo "🌐 URL de la aplicación:"
ALB_DNS=$(aws cloudformation describe-stacks \
  --stack-name $ALB_STACK \
  --query 'Stacks[0].Outputs[?OutputKey==`ALBDNS`].OutputValue' \
  --output text)
echo "   http://$ALB_DNS"
echo ""
echo "🔍 Para verificar:"
echo "   1. Instancia en Target Group: AWS Console > EC2 > Load Balancers > Target Groups"
echo "   2. Health check de contenedores: SSH a la instancia > docker ps"
echo "   3. Logs de aplicación: docker-compose logs"