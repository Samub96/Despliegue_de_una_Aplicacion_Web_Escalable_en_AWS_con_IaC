# 🏗️ Documentación de Manifiestos AWS - Arquitectura de Infraestructura

## 📋 Resumen General

La infraestructura se despliega usando **CloudFormation** con 6 templates principales orquestados por un template maestro.

```
🌐 Internet
    ↓
┌───────────────────────────────────────┐
│  🏗️ main.yaml (Template Maestro)      │
│  ┌─────────────────────────────────┐  │
│  │ 1️⃣ VPC Stack                   │  │
│  │ 2️⃣ RDS Stack                   │  │
│  │ 3️⃣ ALB Stack                   │  │
│  │ 4️⃣ AutoScaling Stack           │  │
│  │ 5️⃣ CloudWatch Stack            │  │
│  └─────────────────────────────────┘  │
└───────────────────────────────────────┘
```

---

## 🎯 Template Principal: `main.yaml`

### Propósito
Orquestador maestro que despliega todos los componentes en orden correcto.

### Dependencias
```
VPC Stack
    ↓
┌─────────┬─────────┐
RDS Stack │ ALB Stack
    ↓           ↓
    AutoScaling Stack
            ↓
    CloudWatch Stack
```

### Parámetros Principales
- 🗃️ **S3TemplateBucket**: Bucket con templates
- 🔑 **KeyName**: Par de llaves SSH
- 📧 **AlertEmail**: Email para alertas
- 🗄️ **DB**: Configuración base de datos

---

## 🌐 1. VPC Stack: `vpc.yaml`

### Propósito
Red virtual privada con subnets públicas y privadas distribuidas en 2 AZ.

```
┌─────────────────────────────────────────┐
│ VPC (10.0.0.0/16)                       │
│                                         │
│ AZ-1a              AZ-1b               │
│ ┌─────────┐        ┌─────────┐         │
│ │Public   │        │Public   │         │
│ │10.0.1.0 │        │10.0.2.0 │         │
│ │/24      │        │/24      │         │
│ └─────────┘        └─────────┘         │
│ ┌─────────┐        ┌─────────┐         │
│ │Private  │        │Private  │         │
│ │10.0.11.0│        │10.0.12.0│         │
│ │/24      │        │/24      │         │
│ └─────────┘        └─────────┘         │
└─────────────────────────────────────────┘
```

### Componentes
- ✅ **VPC**: Red principal
- ✅ **Internet Gateway**: Conectividad internet
- ✅ **Subnets Públicas**: Para ALB y EC2
- ✅ **Subnets Privadas**: Para RDS
- ✅ **Route Tables**: Enrutamiento

### Outputs
- `VpcId`
- `PublicSubnetIds` 
- `PrivateSubnetIds`

---

## 🗄️ 2. RDS Stack: `rds.yaml`

### Propósito
Base de datos MySQL en subnets privadas con alta disponibilidad.

```
┌─────────────────────────────────────────┐
│ RDS MySQL 8.0                           │
│ ┌─────────────┬─────────────────────┐   │
│ │ Primary     │ Multi-AZ Standby    │   │
│ │ AZ-1a       │ AZ-1b               │   │
│ │ Private     │ Private             │   │
│ │ Subnet      │ Subnet              │   │
│ └─────────────┴─────────────────────┘   │
│                                         │
│ 🔒 Security Group:                      │
│    - Port 3306 (MySQL)                 │
│    - Source: VPC CIDR                  │
└─────────────────────────────────────────┘
```

### Configuración
- 🏷️ **Engine**: MySQL 8.0
- 💾 **Storage**: 20GB GP2 (escalable)
- 🏠 **Multi-AZ**: Alta disponibilidad
- 🔒 **Backup**: 7 días retención
- 🌐 **Subnets**: Solo privadas

### Outputs
- `DBEndpoint`
- `DBPort`

---

## ⚖️ 3. ALB Stack: `alb.yaml`

### Propósito
Application Load Balancer para distribuir tráfico HTTP entre instancias.

```
🌐 Internet (Port 80)
        ↓
┌─────────────────────────────────────────┐
│ Application Load Balancer               │
│ ┌─────────────┬─────────────────────┐   │
│ │ Public      │ Public              │   │
│ │ Subnet AZ-1a│ Subnet AZ-1b        │   │
│ └─────────────┴─────────────────────┘   │
│                 ↓                       │
│ ┌─────────────────────────────────────┐ │
│ │ Target Group                        │ │
│ │ - Health Check: /                   │ │
│ │ - Port: 80                          │ │
│ │ - Protocol: HTTP                    │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────┐
│ EC2 Instances (Auto Scaling Group)     │
└─────────────────────────────────────────┘
```

### Componentes
- ✅ **Load Balancer**: Esquema internet-facing
- ✅ **Target Group**: Puerto 80, health check en `/`
- ✅ **Security Group**: Puerto 80 desde anywhere
- ✅ **Listener**: HTTP:80 → Target Group

### Outputs
- `ALBDNS`: URL pública
- `TargetGroupArn`
- `ALBSecurityGroupId`

---

## 🚀 4. AutoScaling Stack: `autoscaling.yaml`

### Propósito
Grupo de auto escalado con instancias EC2 que ejecutan la aplicación dockerizada.

```
┌─────────────────────────────────────────────────┐
│ Auto Scaling Group (Min:1, Desired:2, Max:4)   │
│                                                 │
│ ┌─────────────┐  ┌─────────────┐  ┌───────────┐ │
│ │ EC2 Instance│  │ EC2 Instance│  │ EC2 ...   │ │
│ │ AZ-1a       │  │ AZ-1b       │  │ (Dynamic) │ │
│ │             │  │             │  │           │ │
│ │ 🐳 Docker:   │  │ 🐳 Docker:   │  │ 🐳 Docker: │ │
│ │ - Frontend  │  │ - Frontend  │  │ - Frontend│ │
│ │ - Backend   │  │ - Backend   │  │ - Backend │ │
│ │             │  │             │  │           │ │
│ │ Port 80,8080│  │ Port 80,8080│  │ Port 80.. │ │
│ └─────────────┘  └─────────────┘  └───────────┘ │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ 🔒 Security Group:                              │
│ - SSH (22): 0.0.0.0/0                          │
│ - HTTP (80): 0.0.0.0/0                         │
│ - Backend (8080): 0.0.0.0/0                    │
└─────────────────────────────────────────────────┘
```

### Launch Configuration
```bash
# UserData Script:
1️⃣ Instalar Docker + Docker Compose
2️⃣ Clonar repositorio (rama aws)
3️⃣ Configurar variables de entorno para RDS
4️⃣ Ejecutar: docker-compose up --build -d
   ├── Frontend (nginx): Puerto 80
   ├── Backend (Node.js): Puerto 8080  
   └── Conecta a RDS MySQL
5️⃣ Configurar auto-start en boot
```

### Escalado
- 📊 **Health Check**: ELB + EC2
- ⏱️ **Grace Period**: 5 minutos
- 🎯 **Target Group**: Registro automático

### Outputs
- `AutoScalingGroupName`
- `AppSecurityGroupId`

---

## 📊 5. CloudWatch Stack: `cloudwatch.yaml`

### Propósito
Monitoreo y alertas del Auto Scaling Group.

```
┌─────────────────────────────────────────┐
│ 📊 CloudWatch Monitoring               │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ Metrics:                            │ │
│ │ - CPUUtilization                    │ │
│ │ - NetworkIn/Out                     │ │
│ │ - InstanceCount                     │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ 🚨 Alarms:                          │ │
│ │ - High CPU (>80%)                   │ │
│ │ - Low CPU (<20%)                    │ │
│ │ - Instance Failures                 │ │
│ └─────────────────────────────────────┘ │
│                ↓                        │
│ ┌─────────────────────────────────────┐ │
│ │ 📧 SNS Notifications:               │ │
│ │ - Email: admin@example.com          │ │
│ │ - SMS: (opcional)                   │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

---

## 🔄 Flujo de Tráfico Completo

```
🌐 Usuario
    ↓ HTTP Request
┌─────────────────┐
│ Internet Gateway│
└─────────────────┘
    ↓
┌─────────────────┐
│ Application LB  │ (Puerto 80)
│ Public Subnets  │
└─────────────────┘
    ↓ Load Balancing
┌─────────────────┐
│ Target Group    │
└─────────────────┘
    ↓ Health Check OK
┌─────────────────┐
│ EC2 Instance    │ (Auto Scaling)
│ nginx:80        │
└─────────────────┘
    ↓ Proxy /api/*
┌─────────────────┐
│ Backend:8080    │ (Node.js + Express)
│ (Same Instance) │
└─────────────────┘
    ↓ Database Query
┌─────────────────┐
│ RDS MySQL       │ (Private Subnet)
│ Multi-AZ        │
└─────────────────┘
```

---

## 📁 Estructura de Archivos

```
src/deploy/aws/templates/
├── main.yaml          # 🎭 Orquestador maestro
├── vpc.yaml           # 🌐 Red y conectividad
├── rds.yaml           # 🗄️ Base de datos
├── alb.yaml           # ⚖️ Load balancer
├── autoscaling.yaml   # 🚀 Instancias EC2
├── cloudwatch.yaml    # 📊 Monitoreo
└── sns.yaml           # 📧 Notificaciones
```

---

## 🎯 Ventajas de Esta Arquitectura

### ✅ **Escalabilidad**
- Auto Scaling automático según demanda
- Load Balancer distribuye tráfico
- RDS Multi-AZ para alta disponibilidad

### ✅ **Seguridad** 
- RDS en subnets privadas
- Security Groups restrictivos
- ALB como único punto de entrada

### ✅ **Mantenibilidad**
- docker-compose.yml unificado
- UserData automatizado
- CloudWatch monitoring

### ✅ **Costo-Eficiencia**
- t3.micro instances (Free Tier)
- Auto scaling down cuando no hay carga
- Storage optimizado

---

## 🚀 Comandos de Deployment

```bash
# 1. Subir templates a S3
aws s3 sync templates/ s3://mi-bucket-templates/

# 2. Deployar stack maestro
./deploy.sh

# 3. Verificar deployment
aws cloudformation describe-stacks --stack-name ProyectoFinalStack
```