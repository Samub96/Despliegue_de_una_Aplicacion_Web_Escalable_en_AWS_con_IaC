#!/bin/bash

# Script para usar SOLO Auto Scaling Group con configuración unificada
# Elimina la instancia EC2 individual redundante

set -e

echo "🔄 Configurando arquitectura unificada con Auto Scaling..."

# Eliminar instancia EC2 individual (redundante)
EC2_STACK="ecommerce-ec2-stack"
if aws cloudformation describe-stacks --stack-name $EC2_STACK >/dev/null 2>&1; then
  echo "⚠️  Eliminando instancia EC2 individual (será reemplazada por ASG)..."
  aws cloudformation delete-stack --stack-name $EC2_STACK
  aws cloudformation wait stack-delete-complete --stack-name $EC2_STACK
  echo "✅ Instancia individual eliminada"
fi

# Obtener parámetros necesarios
VPC_STACK="ecommerce-vpc-stack"
RDS_STACK="ecommerce-rds-stack"
ALB_STACK="ecommerce-alb-stack"
ASG_STACK="ecommerce-autoscaling-stack"

VPC_ID=$(aws cloudformation describe-stacks \
  --stack-name $VPC_STACK \
  --query 'Stacks[0].Outputs[?OutputKey==`VpcId`].OutputValue' \
  --output text)

PUBLIC_SUBNETS=$(aws cloudformation describe-stacks \
  --stack-name $VPC_STACK \
  --query 'Stacks[0].Outputs[?OutputKey==`PublicSubnetIds`].OutputValue' \
  --output text)

ALB_SG=$(aws cloudformation describe-stacks \
  --stack-name $ALB_STACK \
  --query 'Stacks[0].Outputs[?OutputKey==`ALBSecurityGroupId`].OutputValue' \
  --output text)

TARGET_GROUP_ARN=$(aws cloudformation describe-stacks \
  --stack-name $ALB_STACK \
  --query 'Stacks[0].Outputs[?OutputKey==`TargetGroupArn`].OutputValue' \
  --output text)

DB_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name $RDS_STACK \
  --query 'Stacks[0].Outputs[?OutputKey==`DBEndpoint`].OutputValue' \
  --output text)

echo "✅ Parámetros obtenidos"

# Actualizar/crear Auto Scaling Group con configuración unificada
echo ""
echo "📦 Desplegando Auto Scaling Group con docker-compose unificado..."

if aws cloudformation describe-stacks --stack-name $ASG_STACK >/dev/null 2>&1; then
  aws cloudformation update-stack \
    --stack-name $ASG_STACK \
    --template-body file://templates/autoscaling.yaml \
    --parameters \
      ParameterKey=KeyName,ParameterValue=my-key \
      ParameterKey=SecurityGroupId,ParameterValue=$ALB_SG \
      ParameterKey=SubnetIds,ParameterValue="$PUBLIC_SUBNETS" \
      ParameterKey=TargetGroupArn,ParameterValue=$TARGET_GROUP_ARN \
      ParameterKey=DBEndpoint,ParameterValue=$DB_ENDPOINT \
      ParameterKey=DBPassword,ParameterValue=SecurePassword123 \
      ParameterKey=DesiredCapacity,ParameterValue=2
  aws cloudformation wait stack-update-complete --stack-name $ASG_STACK
else
  aws cloudformation create-stack \
    --stack-name $ASG_STACK \
    --template-body file://templates/autoscaling.yaml \
    --parameters \
      ParameterKey=KeyName,ParameterValue=my-key \
      ParameterKey=SecurityGroupId,ParameterValue=$ALB_SG \
      ParameterKey=SubnetIds,ParameterValue="$PUBLIC_SUBNETS" \
      ParameterKey=TargetGroupArn,ParameterValue=$TARGET_GROUP_ARN \
      ParameterKey=DBEndpoint,ParameterValue=$DB_ENDPOINT \
      ParameterKey=DBPassword,ParameterValue=SecurePassword123 \
      ParameterKey=DesiredCapacity,ParameterValue=2
  aws cloudformation wait stack-create-complete --stack-name $ASG_STACK
fi

# Obtener URL final
ALB_DNS=$(aws cloudformation describe-stacks \
  --stack-name $ALB_STACK \
  --query 'Stacks[0].Outputs[?OutputKey==`ALBDNS`].OutputValue' \
  --output text)

echo ""
echo "🎉 Deployment completado con arquitectura unificada!"
echo ""
echo "🏗️  Arquitectura final:"
echo "   • Auto Scaling Group (2+ instancias)"
echo "   • Todas usan docker-compose.yml + override"
echo "   • Registradas automáticamente en ALB"
echo "   • Conectadas a RDS MySQL"
echo ""
echo "🌐 URL de la aplicación:"
echo "   http://$ALB_DNS"
echo ""
echo "🔍 Verificar instancias:"
echo "   aws ec2 describe-instances --filters \"Name=tag:Name,Values=app-asg-instance\" --query 'Reservations[].Instances[].{Id:InstanceId,State:State.Name,IP:PublicIpAddress}'"