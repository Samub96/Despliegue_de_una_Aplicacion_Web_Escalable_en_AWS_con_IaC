#!/bin/bash
# =============================================
# Script de despliegue AWS - Proyecto Final 2025
# Autor: Samuel
# Requiere: AWS CLI y archivo aws_credentials.txt con credenciales del sandbox
# =============================================

# ======== CONFIGURACIÓN GENERAL ========
STACK_NAME="ProyectoFinalStack"
BUCKET="proyecto-final-samuel"
REGION="us-east-1"
KEY_PAIR="test"                      # ⚠️ Nombre del Key Pair registrado en AWS (sin .pem)
ADMIN_EMAIL="samuel.barona@u.icesi.edu.co"      # ⚠️ Cambia por tu correo
DB_PASSWORD="ProjFinal#2025"                   # ⚠️ Usa una contraseña segura
TEMPLATES_PATH="templates"
CRED_FILE="secrets/aws_credentials.txt"
PEM_FILE="secrets/test.pem"

##======= DEBUG: LISTAR ARCHIVOS ========
## "---------------------------------------"
##cat secrets/aws_credentials.txt
 ##"---------------------------------------"
# ======== LEER CREDENCIALES DESDE TXT ========
echo "🔐 Leyendo credenciales desde ${CRED_FILE}..."


if [ ! -f "$CRED_FILE" ]; then
    echo "❌ Archivo de credenciales no encontrado: $CRED_FILE"
    echo "➡️  Crea el archivo con este formato:"
    echo "aws_access_key_id=ASIAXXXXX"
    echo "aws_secret_access_key=wJalrXXXX"
    echo "aws_session_token=IQoJXXXX..."
    exit 1
fi

AWS_ACCESS_KEY_ID=$(grep -m1 "aws_access_key_id" $CRED_FILE | cut -d'=' -f2 | xargs)
AWS_SECRET_ACCESS_KEY=$(grep -m1 "aws_secret_access_key" $CRED_FILE | cut -d'=' -f2 | xargs)
AWS_SESSION_TOKEN=$(grep -m1 "aws_session_token" $CRED_FILE | cut -d'=' -f2- | xargs)

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_SESSION_TOKEN" ]; then
    echo "❌ El archivo $CRED_FILE no tiene las 3 credenciales requeridas."
    exit 1
fi

mkdir -p ~/.aws

cat > ~/.aws/credentials <<EOF
[default]
aws_access_key_id=${AWS_ACCESS_KEY_ID}
aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}
aws_session_token=${AWS_SESSION_TOKEN}
EOF

cat > ~/.aws/config <<EOF
[default]
region=${REGION}
output=json
EOF

echo "✅ Credenciales configuradas correctamente."

# ======== VALIDACIÓN PREVIA ========
echo "🔍 Verificando instalación de AWS CLI..."
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI no está instalado. Instálalo con: sudo apt install awscli"
    exit 1
fi
echo "✅ AWS CLI detectado."

echo "🧾 Verificando autenticación AWS..."
if ! aws sts get-caller-identity &>/dev/null; then
    echo "❌ No se pudo autenticar en AWS. Verifica las credenciales en ${CRED_FILE}"
    exit 1
fi
echo "✅ Autenticación exitosa."

# ======== VALIDAR EXISTENCIA DEL KEY PAIR LOCAL ========
if [ -f "$PEM_FILE" ]; then
    chmod 400 "$PEM_FILE"
    echo "✅ Clave privada detectada y permisos ajustados: ${PEM_FILE}"
else
    echo "⚠️  Advertencia: No se encontró el archivo PEM en ${PEM_FILE}"
fi

# ======== BUCKET S3 ========
echo "📦 Verificando bucket S3..."
if ! aws s3 ls "s3://${BUCKET}" --region $REGION &>/dev/null; then
    echo "⚙️  Creando bucket S3 ${BUCKET}..."
    aws s3 mb s3://${BUCKET} --region $REGION
else
    echo "✅ Bucket ${BUCKET} encontrado."
fi

# ======== SUBIR PLANTILLAS ========
echo "📤 Subiendo templates CloudFormation a S3..."
aws s3 cp $TEMPLATES_PATH s3://${BUCKET}/ --recursive 

if [ $? -ne 0 ]; then
    echo "❌ Error subiendo templates. Verifica el path y permisos."
    exit 1
fi
echo "✅ Templates subidos correctamente."


# ======== DESPLEGAR STACK PRINCIPAL ========
echo "🔗 Generando URL de plantilla principal..."
MAIN_URL="https://s3.${REGION}.amazonaws.com/${BUCKET}/main.yaml"

# Alternativa más segura (usa presign):
# MAIN_URL=$(aws s3 presign s3://${BUCKET}/main.yaml --expires-in 3600)

echo "📄 Usando template: ${MAIN_URL}"


echo "🚀 Creando stack ${STACK_NAME} en CloudFormation..."
aws cloudformation create-stack \
  --stack-name ${STACK_NAME} \
  --template-url ${MAIN_URL} \
  --parameters \
      ParameterKey=KeyName,ParameterValue=${KEY_PAIR} \
      ParameterKey=AdminEmail,ParameterValue=${ADMIN_EMAIL} \
      ParameterKey=DBPassword,ParameterValue=${DB_PASSWORD} \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ${REGION}

if [ $? -ne 0 ]; then
    echo "❌ Error creando el stack."
    exit 1
fi

echo "🕒 Esperando a que el stack se complete..."
aws cloudformation wait stack-create-complete --stack-name ${STACK_NAME} --region ${REGION}

if [ $? -eq 0 ]; then
    echo "✅ Stack desplegado correctamente."
else
    echo "❌ Error durante el despliegue."
    exit 1
fi

# ======== MOSTRAR RESULTADOS ========
echo "📋 Outputs del stack:"
aws cloudformation describe-stacks \
  --stack-name ${STACK_NAME} \
  --region ${REGION} \
  --query "Stacks[0].Outputs[*].[OutputKey,OutputValue]" \
  --output table

# ======== URL DE ACCESO ========
ALB_DNS=$(aws cloudformation describe-stacks \
  --stack-name ${STACK_NAME} \
  --region ${REGION} \
  --query "Stacks[0].Outputs[?OutputKey=='ALBDNS'].OutputValue" \
  --output text)

if [ "$ALB_DNS" != "None" ]; then
    echo "🌐 Tu aplicación está disponible en: http://${ALB_DNS}"
else
    echo "⚠️ No se encontró ALB_DNS en los outputs. Revisa el template."
fi

echo "🎉 Despliegue completo."
