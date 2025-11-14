#!/bin/bash
# Script de diagnóstico rápido para AWS

echo "🔍 DIAGNÓSTICO DEL DESPLIEGUE AWS"
echo "================================="

# Configurar credenciales
source secrets/aws_credentials.txt
export AWS_ACCESS_KEY_ID=$aws_access_key_id
export AWS_SECRET_ACCESS_KEY=$aws_secret_access_key
export AWS_SESSION_TOKEN=$aws_session_token

STACK_NAME="ProyectoFinalStack"

echo "📋 1. Estado del Stack CloudFormation:"
aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].{Status:StackStatus,CreatedTime:CreationTime}" --output table 2>/dev/null || echo "❌ No se pudo obtener información del stack"

echo ""
echo "🌐 2. Load Balancer DNS:"
ALB_DNS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='ALBDNS'].OutputValue" --output text 2>/dev/null)
if [ "$ALB_DNS" != "None" ] && [ ! -z "$ALB_DNS" ]; then
    echo "✅ ALB DNS: $ALB_DNS"
else
    echo "❌ No se encontró ALB DNS"
fi

echo ""
echo "🖥️ 3. Instancias EC2:"
aws ec2 describe-instances \
    --filters "Name=tag:aws:cloudformation:stack-name,Values=$STACK_NAME" "Name=instance-state-name,Values=running" \
    --query "Reservations[].Instances[].{InstanceId:InstanceId,PublicIP:PublicIpAddress,LaunchTime:LaunchTime}" \
    --output table 2>/dev/null || echo "❌ No se pudieron obtener las instancias"

echo ""
echo "⏰ 4. Tiempo estimado de inicialización:"
LAUNCH_TIME=$(aws ec2 describe-instances \
    --filters "Name=tag:aws:cloudformation:stack-name,Values=$STACK_NAME" "Name=instance-state-name,Values=running" \
    --query "Reservations[0].Instances[0].LaunchTime" \
    --output text 2>/dev/null)

if [ ! -z "$LAUNCH_TIME" ] && [ "$LAUNCH_TIME" != "None" ]; then
    echo "🚀 Instancia lanzada en: $LAUNCH_TIME"
    echo "⏳ La aplicación puede tardar 5-10 minutos en estar lista después del lanzamiento"
else
    echo "❌ No se pudo determinar el tiempo de lanzamiento"
fi

echo ""
echo "🔗 5. Probando conectividad:"
if [ ! -z "$ALB_DNS" ] && [ "$ALB_DNS" != "None" ]; then
    echo "Probando: http://$ALB_DNS"
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "http://$ALB_DNS" 2>/dev/null || echo "000")
    echo "Estado HTTP: $HTTP_STATUS"
    
    if [ "$HTTP_STATUS" = "502" ]; then
        echo "🔄 Error 502 - Las instancias aún se están inicializando"
        echo "   Espera 5-10 minutos y vuelve a intentar"
    elif [ "$HTTP_STATUS" = "200" ]; then
        echo "✅ ¡Aplicación funcionando!"
    else
        echo "⚠️ Estado: $HTTP_STATUS"
    fi
fi

echo ""
echo "💡 RECOMENDACIONES:"
echo "- Si ves error 502: Espera 5-10 minutos más"
echo "- Luego refresca: http://$ALB_DNS"
echo "- Para ver logs de instancia, usa AWS Console > EC2 > Instancias > Actions > Monitor and troubleshoot > Get system log"