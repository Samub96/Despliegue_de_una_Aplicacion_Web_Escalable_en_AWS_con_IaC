#!/bin/bash

# Script para desactivar Auto Scaling Group y usar solo instancia EC2 individual
# Esto evita conflictos y simplifica la arquitectura

set -e

ASG_STACK="ecommerce-autoscaling-stack"

echo "🔄 Verificando si existe el stack de Auto Scaling..."

if aws cloudformation describe-stacks --stack-name $ASG_STACK >/dev/null 2>&1; then
  echo "⚠️  Stack de Auto Scaling encontrado. Eliminando para evitar conflictos..."
  
  # Reducir capacidad a 0 primero (graceful shutdown)
  aws autoscaling update-auto-scaling-group \
    --auto-scaling-group-name $(aws cloudformation describe-stack-resource \
      --stack-name $ASG_STACK \
      --logical-resource-id AutoScalingGroup \
      --query 'StackResourceDetail.PhysicalResourceId' \
      --output text) \
    --desired-capacity 0 \
    --min-size 0 \
    --max-size 0 || true

  echo "⏳ Esperando a que las instancias del ASG se terminen..."
  sleep 60

  # Eliminar stack completo
  aws cloudformation delete-stack --stack-name $ASG_STACK
  
  echo "⏳ Esperando a que el stack se elimine completamente..."
  aws cloudformation wait stack-delete-complete --stack-name $ASG_STACK
  
  echo "✅ Stack de Auto Scaling eliminado"
else
  echo "✅ No hay stack de Auto Scaling activo"
fi

echo ""
echo "🎯 Ahora el ALB apuntará solo a la instancia EC2 individual (app-instance)"
echo "💡 La instancia principal será registrada automáticamente al Target Group"