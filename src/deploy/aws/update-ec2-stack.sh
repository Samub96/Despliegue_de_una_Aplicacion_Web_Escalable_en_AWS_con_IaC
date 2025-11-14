#!/bin/bash

# Script para actualizar el stack de EC2 con la configuración corregida
# Usa el docker-compose.yml existente en lugar de crear uno nuevo

set -e

STACK_NAME="ecommerce-ec2-stack"
VPC_STACK="ecommerce-vpc-stack"
RDS_STACK="ecommerce-rds-stack"

echo "🔄 Actualizando stack EC2 con configuración corregida..."

# Obtener outputs necesarios
VPC_ID=$(aws cloudformation describe-stacks \
  --stack-name $VPC_STACK \
  --query 'Stacks[0].Outputs[?OutputKey==`VpcId`].OutputValue' \
  --output text)

PUBLIC_SUBNETS=$(aws cloudformation describe-stacks \
  --stack-name $VPC_STACK \
  --query 'Stacks[0].Outputs[?OutputKey==`PublicSubnetIds`].OutputValue' \
  --output text)

DB_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name $RDS_STACK \
  --query 'Stacks[0].Outputs[?OutputKey==`DBEndpoint`].OutputValue' \
  --output text)

echo "✅ Obtenidos los parámetros necesarios"
echo "   VPC: $VPC_ID"
echo "   Subnets: $PUBLIC_SUBNETS"
echo "   DB: $DB_ENDPOINT"

# Verificar si el stack existe
if aws cloudformation describe-stacks --stack-name $STACK_NAME >/dev/null 2>&1; then
  echo "📝 Actualizando stack existente..."
  aws cloudformation update-stack \
    --stack-name $STACK_NAME \
    --template-body file://templates/ec2.yaml \
    --parameters \
      ParameterKey=VpcId,ParameterValue=$VPC_ID \
      ParameterKey=PublicSubnetIds,ParameterValue="$PUBLIC_SUBNETS" \
      ParameterKey=KeyName,ParameterValue=my-key \
      ParameterKey=DBEndpoint,ParameterValue=$DB_ENDPOINT \
      ParameterKey=DBPassword,ParameterValue=SecurePassword123

  echo "⏳ Esperando a que la actualización complete..."
  aws cloudformation wait stack-update-complete --stack-name $STACK_NAME
else
  echo "📦 Creando nuevo stack..."
  aws cloudformation create-stack \
    --stack-name $STACK_NAME \
    --template-body file://templates/ec2.yaml \
    --parameters \
      ParameterKey=VpcId,ParameterValue=$VPC_ID \
      ParameterKey=PublicSubnetIds,ParameterValue="$PUBLIC_SUBNETS" \
      ParameterKey=KeyName,ParameterValue=my-key \
      ParameterKey=DBEndpoint,ParameterValue=$DB_ENDPOINT \
      ParameterKey=DBPassword,ParameterValue=SecurePassword123

  echo "⏳ Esperando a que la creación complete..."
  aws cloudformation wait stack-create-complete --stack-name $STACK_NAME
fi

# Obtener la IP de la instancia
INSTANCE_IP=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query 'Stacks[0].Outputs[?OutputKey==`AppInstanceId`].OutputValue' \
  --output text)

echo ""
echo "🎉 Stack actualizado exitosamente"
echo "💡 Instancia ID: $INSTANCE_IP"
echo ""
echo "Para conectarte a la instancia:"
echo "  aws ec2 describe-instances --instance-ids $INSTANCE_IP --query 'Reservations[0].Instances[0].PublicIpAddress' --output text"
echo ""
echo "Luego SSH:"
echo "  ssh -i my-key.pem ec2-user@<IP_PUBLICA>"
echo ""
echo "Verificar contenedores:"
echo "  docker ps"
echo "  docker-compose logs"