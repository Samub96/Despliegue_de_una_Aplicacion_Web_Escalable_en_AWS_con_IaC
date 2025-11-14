#!/bin/bash
# Script de diagnóstico de Health Checks detallado

echo "🏥 DIAGNÓSTICO DETALLADO DE HEALTH CHECKS"
echo "=========================================="

# Configurar credenciales
source secrets/aws_credentials.txt
export AWS_ACCESS_KEY_ID=$aws_access_key_id
export AWS_SECRET_ACCESS_KEY=$aws_secret_access_key
export AWS_SESSION_TOKEN=$aws_session_token

STACK_NAME="ProyectoFinalStack"
REGION="us-east-1"

echo "🔍 1. ESTADO DE INSTANCIAS EC2"
echo "--------------------------------"
INSTANCES=$(aws ec2 describe-instances \
    --filters "Name=tag:aws:cloudformation:stack-name,Values=$STACK_NAME" \
    --query "Reservations[].Instances[?State.Name=='running'].[InstanceId,PublicIpAddress,LaunchTime,State.Name]" \
    --output text 2>/dev/null)

if [ ! -z "$INSTANCES" ]; then
    echo "$INSTANCES" | while read INSTANCE_ID PUBLIC_IP LAUNCH_TIME STATE; do
        echo "📊 Instancia: $INSTANCE_ID"
        echo "   🌐 IP Pública: $PUBLIC_IP"
        echo "   🚀 Lanzada: $LAUNCH_TIME"
        echo "   ⚡ Estado: $STATE"
        echo ""
        
        if [ ! -z "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "None" ]; then
            echo "   🔗 Probando conectividad directa a la instancia:"
            
            # Probar puerto 80 (nginx)
            echo "   - Puerto 80 (Frontend):"
            timeout 5 bash -c "</dev/tcp/$PUBLIC_IP/80" 2>/dev/null && echo "     ✅ Puerto 80 abierto" || echo "     ❌ Puerto 80 cerrado"
            
            # Probar puerto 8080 (backend)
            echo "   - Puerto 8080 (Backend):"
            timeout 5 bash -c "</dev/tcp/$PUBLIC_IP/8080" 2>/dev/null && echo "     ✅ Puerto 8080 abierto" || echo "     ❌ Puerto 8080 cerrado"
            
            # Probar HTTP en puerto 80
            echo "   - HTTP en puerto 80:"
            HTTP_RESPONSE=$(curl -s --max-time 5 "http://$PUBLIC_IP" 2>/dev/null | head -c 50)
            if [ ! -z "$HTTP_RESPONSE" ]; then
                echo "     ✅ HTTP responde: $(echo $HTTP_RESPONSE | tr -d '\n')"
            else
                echo "     ❌ HTTP no responde"
            fi
            
            # Probar health endpoint
            echo "   - Health endpoint:"
            HEALTH_RESPONSE=$(curl -s --max-time 5 "http://$PUBLIC_IP/health" 2>/dev/null)
            if [ "$HEALTH_RESPONSE" = "healthy" ]; then
                echo "     ✅ Health check OK"
            else
                echo "     ❌ Health check falla: $HEALTH_RESPONSE"
            fi
        fi
        echo "   ----------------------------------------"
    done
else
    echo "❌ No se encontraron instancias en ejecución"
fi

echo ""
echo "🎯 2. TARGET GROUPS Y ALB"
echo "-------------------------"

# Buscar target groups
TG_INFO=$(aws elbv2 describe-target-groups \
    --query "TargetGroups[?contains(TargetGroupName, 'ProyectoFinal') || contains(TargetGroupName, 'project')].{Name:TargetGroupName,ARN:TargetGroupArn,Port:Port,HealthPath:HealthCheckPath}" \
    --output json 2>/dev/null)

if [ "$TG_INFO" != "[]" ] && [ ! -z "$TG_INFO" ]; then
    echo "$TG_INFO" | jq -r '.[] | "📋 Target Group: \(.Name)\n   🔗 ARN: \(.ARN)\n   🚪 Puerto: \(.Port)\n   ❤️ Health Path: \(.HealthPath)\n"'
    
    # Obtener ARN del primer target group
    TG_ARN=$(echo "$TG_INFO" | jq -r '.[0].ARN' 2>/dev/null)
    
    if [ ! -z "$TG_ARN" ] && [ "$TG_ARN" != "null" ]; then
        echo "🏥 Estado de Health Checks:"
        aws elbv2 describe-target-health --target-group-arn "$TG_ARN" \
            --query "TargetHealthDescriptions[].{Target:Target.Id,Port:Target.Port,Health:TargetHealth.State,Reason:TargetHealth.Reason}" \
            --output table 2>/dev/null || echo "❌ No se pudo obtener estado de health checks"
    fi
else
    echo "❌ No se encontraron target groups"
fi

echo ""
echo "🔧 3. AUTO SCALING GROUP"
echo "------------------------"
ASG_INFO=$(aws autoscaling describe-auto-scaling-groups \
    --query "AutoScalingGroups[?contains(AutoScalingGroupName, 'ProyectoFinal') || contains(AutoScalingGroupName, 'project')].{Name:AutoScalingGroupName,Desired:DesiredCapacity,Min:MinSize,Max:MaxSize,Instances:length(Instances)}" \
    --output table 2>/dev/null)

if [ ! -z "$ASG_INFO" ]; then
    echo "$ASG_INFO"
else
    echo "❌ No se encontró Auto Scaling Group"
fi

echo ""
echo "📊 4. EVENTOS DE AUTO SCALING"
echo "------------------------------"
aws autoscaling describe-scaling-activities \
    --auto-scaling-group-name $(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[?contains(AutoScalingGroupName, 'ProyectoFinal') || contains(AutoScalingGroupName, 'project')].AutoScalingGroupName" --output text 2>/dev/null) \
    --max-items 5 \
    --query "Activities[].{StartTime:StartTime,StatusCode:StatusCode,Description:Description}" \
    --output table 2>/dev/null || echo "❌ No se pudieron obtener eventos de Auto Scaling"

echo ""
echo "💡 ANÁLISIS Y RECOMENDACIONES:"
echo "==============================="
echo "Si las instancias están 'running' pero los puertos están cerrados:"
echo "- El user-data script aún está ejecutándose"
echo "- Docker puede estar instalándose o compilando"
echo "- Revisa los logs de la instancia en AWS Console"
echo ""
echo "Si los health checks fallan:"
echo "- Verifica que el health check path sea correcto (/health)"
echo "- Confirma que nginx esté corriendo en puerto 80"
echo "- Revisa la configuración del security group"