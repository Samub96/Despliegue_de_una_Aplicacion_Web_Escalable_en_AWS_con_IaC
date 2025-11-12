# 🐳 Aplicación E-commerce Dockerizada

## 📋 Resumen de Cambios

Esta versión de la aplicación ha sido completamente **dockerizada** para garantizar:
- ✅ **Consistencia** entre entornos de desarrollo y producción
- ✅ **Escalabilidad** automática en AWS
- ✅ **Despliegue simplificado** con un solo comando
- ✅ **Aislamiento** de dependencias

---

## 🏗️ Arquitectura Dockerizada

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │    Backend      │    │     MySQL       │
│   (Nginx)       │◄───┤   (Node.js)     │◄───┤   (Database)    │
│   Port: 3000    │    │   Port: 8080    │    │   Port: 3306    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 🔧 Servicios

1. **MySQL Database**
   - Imagen: `mysql:8.0`
   - Puerto: `3306`
   - Base de datos: `ecommerce_db`
   - Health checks incluidos

2. **Backend API**
   - Build: `./src/backend/Dockerfile`
   - Puerto: `8080`
   - Variables de entorno configurables
   - Health endpoint: `/api/health`

3. **Frontend Web**
   - Build: `./src/frontend/Dockerfile`
   - Puerto: `3000` (mapea al 80 interno)
   - Nginx con proxy reverso al backend
   - Health endpoint: `/health`

---

## 🚀 Uso Local

### Requisitos Previos
- Docker & Docker Compose instalados
- Puertos 3000, 8080, 3306 disponibles

### Comandos

```bash
# Iniciar toda la aplicación
docker-compose up --build -d

# Ver logs
docker-compose logs -f

# Ver estado de servicios
docker-compose ps

# Parar aplicación
docker-compose down
```

### 🌐 URLs de Acceso
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8080
- **Health Checks**: 
  - Frontend: http://localhost:3000/health
  - Backend: http://localhost:8080/api/health
  - API Products: http://localhost:3000/api/products

---

## ☁️ Despliegue en AWS

### Cambios en las Plantillas CloudFormation

#### 1. **EC2.yaml**
- ✅ Instalación automática de Docker & Docker Compose
- ✅ Build y ejecución de contenedores
- ✅ Systemd service para auto-restart
- ✅ Configuración dinámica de base de datos RDS

#### 2. **AutoScaling.yaml** 
- ✅ Misma configuración Docker para instancias del ASG
- ✅ Health checks mejorados
- ✅ Registro automático en el ALB

#### 3. **Deploy.sh**
- ✅ Validación post-despliegue automatizada
- ✅ Testing de endpoints críticos
- ✅ URLs importantes mostradas al final

### 🔧 Configuración de Producción

```yaml
# docker-compose.prod.yml (generado automáticamente)
services:
  backend:
    environment:
      - DB_HOST=${DBEndpoint}  # RDS endpoint
      - DB_NAME=${DBName}
      - DB_USER=${DBUser}
      - DB_PASSWORD=${DBPassword}
      - NODE_ENV=production
  frontend:
    # Proxy configurado para el backend interno
```

---

## 📊 Monitoreo y Health Checks

### Health Endpoints Disponibles
- `GET /health` - Frontend nginx health
- `GET /api/health` - Backend application health

### Docker Health Checks
- **MySQL**: `mysqladmin ping`
- **Backend**: `wget /api/health`
- **Frontend**: `wget /health`

### Logging
```bash
# Ver logs en tiempo real
docker-compose logs -f [service_name]

# Logs específicos
docker-compose logs backend
docker-compose logs frontend
docker-compose logs mysql
```

---

## 🔄 Flujo de Desarrollo

### 1. Desarrollo Local
```bash
# Hacer cambios en el código
# Rebuild y restart
docker-compose up --build
```

### 2. Testing
```bash
# Probar health checks
curl http://localhost:3000/health
curl http://localhost:8080/api/health

# Probar funcionalidad
curl http://localhost:3000/api/products
```

### 3. Despliegue
```bash
git add .
git commit -m "feat: new feature"
git push origin aws

# Ejecutar despliegue AWS
cd src/deploy/aws
./deploy.sh
```

---

## 🐳 Ventajas de la Dockerización

### ✅ **Consistencia**
- Mismo entorno en desarrollo, testing y producción
- Eliminación de problemas "funciona en mi máquina"

### ✅ **Escalabilidad**
- Contenedores ligeros para Auto Scaling
- Health checks nativos
- Restart automático en fallos

### ✅ **Mantenimiento**
- Actualizaciones de dependencias encapsuladas
- Rollback rápido con tags de imágenes
- Logs centralizados

### ✅ **Seguridad**
- Aislamiento de procesos
- Usuario no-root en contenedores
- Secrets management integrado

---

## 🔧 Troubleshooting

### Problemas Comunes

**Puerto en uso**
```bash
lsof -ti:8080 | xargs kill -9
docker-compose down
docker-compose up -d
```

**Base de datos no conecta**
```bash
docker-compose logs mysql
docker-compose logs backend
```

**Frontend no carga**
```bash
curl http://localhost:3000/health
docker-compose logs frontend
```

### Comandos de Debug
```bash
# Entrar a un contenedor
docker-compose exec backend bash
docker-compose exec frontend sh

# Verificar redes
docker network ls
docker network inspect [network_name]

# Rebuild completo
docker-compose down -v
docker system prune -a
docker-compose up --build
```

---

## 📈 Próximos Pasos

1. **CI/CD Pipeline**: Automatizar build y deploy con GitHub Actions
2. **Monitoring**: Agregar Prometheus y Grafana
3. **Secrets**: Usar AWS Secrets Manager en producción
4. **Backup**: Automatizar backups de base de datos
5. **SSL/TLS**: Configurar HTTPS con certificados

---

## 🎯 Estado Actual

✅ **Completado**
- Dockerización completa de la aplicación
- Health checks implementados
- Proxy nginx funcionando
- Despliegue local operativo
- Plantillas AWS actualizadas
- Script de despliegue mejorado

🔄 **Listo para**
- Despliegue en AWS con un comando
- Escalado automático
- Monitoreo en CloudWatch
- Producción

---

*Documentación actualizada el 12 de noviembre de 2025*
*Versión: 2.0 - Dockerizada*