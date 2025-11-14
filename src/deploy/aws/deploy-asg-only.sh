#!/bin/bash

# Script para deployar solo con Auto Scaling Group (sin EC2 individual)
# Usa docker-compose.yml unificado

set -e

echo "🚀 Desplegando aplicación con Auto Scaling Group unificado..."

# Verificar que no existe stack EC2 individual (eliminar si existe)
EC2_STACK="ecommerce-ec2-stack"
if aws cloudformation describe-stacks --stack-name $EC2_STACK >/dev/null 2>&1; then
  echo "⚠️  Eliminando stack EC2 individual redundante..."
  aws cloudformation delete-stack --stack-name $EC2_STACK
  echo "⏳ Esperando eliminación..."
  aws cloudformation wait stack-delete-complete --stack-name $EC2_STACK
  echo "✅ Stack EC2 eliminado"
fi

# Obtener parámetros necesarios de stacks existentes
VPC_STACK="ecommerce-vpc-stack"
RDS_STACK="ecommerce-rds-stack"
ALB_STACK="ecommerce-alb-stack"
ASG_STACK="ecommerce-autoscaling-stack"

echo "📋 Obteniendo parámetros de infraestructura..."

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

echo "✅ Parámetros obtenidos:"
echo "   VPC: $VPC_ID"
echo "   Subnets: $PUBLIC_SUBNETS"
echo "   Security Group: $ALB_SG"
echo "   Target Group: $TARGET_GROUP_ARN"
echo "   RDS Endpoint: $DB_ENDPOINT"

# Desplegar/actualizar Auto Scaling Group
echo ""
echo "📦 Desplegando Auto Scaling Group..."

if aws cloudformation describe-stacks --stack-name $ASG_STACK >/dev/null 2>&1; then
  echo "🔄 Actualizando stack existente..."
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
      ParameterKey=DesiredCapacity,ParameterValue=2 \
      ParameterKey=MinSize,ParameterValue=1 \
      ParameterKey=MaxSize,ParameterValue=4

  echo "⏳ Esperando actualización..."
  aws cloudformation wait stack-update-complete --stack-name $ASG_STACK
else
  echo "📦 Creando nuevo stack..."
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
      ParameterKey=DesiredCapacity,ParameterValue=2 \
      ParameterKey=MinSize,ParameterValue=1 \
      ParameterKey=MaxSize,ParameterValue=4

  echo "⏳ Esperando creación..."
  aws cloudformation wait stack-create-complete --stack-name $ASG_STACK
fi

# Obtener URL final
ALB_DNS=$(aws cloudformation describe-stacks \
  --stack-name $ALB_STACK \
  --query 'Stacks[0].Outputs[?OutputKey==`ALBDNS`].OutputValue' \
  --output text)

echo ""
echo "🎉 Deployment completado exitosamente!"
echo ""
echo "🏗️  Arquitectura final:"
echo "   • Auto Scaling Group con 2-4 instancias"
echo "   • Todas usan docker-compose.yml + override"
echo "   • Registradas automáticamente en ALB Target Group"
echo "   • Conectadas a RDS MySQL"
echo ""
echo "🌐 URL de la aplicación:"
echo "   http://$ALB_DNS"
echo ""
echo "🔍 Verificar instancias:"
echo '   aws ec2 describe-instances --filters "Name=tag:Name,Values=app-asg-instance" --query "Reservations[].Instances[].{Id:InstanceId,State:State.Name,IP:PublicIpAddress}" --output table'
echo ""
echo "📊 Ver Target Group health:"
echo "   aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN"