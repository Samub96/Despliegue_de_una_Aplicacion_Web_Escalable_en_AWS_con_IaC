FROM nginx:alpine

# Copiar archivos estáticos del frontend
COPY . /usr/share/nginx/html/

# Crear configuración de nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Exponer puerto 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80/health || exit 1

# El CMD por defecto de nginx es suficiente
CMD ["nginx", "-g", "daemon off;"]