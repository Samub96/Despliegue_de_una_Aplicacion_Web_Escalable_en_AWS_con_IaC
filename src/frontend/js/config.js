// Configuración dinámica para desarrollo local y producción
window.APP_CONFIG = {
  // Detectar si estamos en desarrollo local o producción
  isDevelopment: window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1',
  
  // URL base del API dependiendo del entorno
  getApiBaseUrl() {
    if (this.isDevelopment) {
      // Desarrollo local: usar el proxy de nginx o directamente el backend
      return window.location.origin + '/api';
    } else {
      // Producción en AWS: usar el mismo dominio con proxy
      return window.location.origin + '/api';
    }
  },

  // URL completa para endpoints específicos
  getApiUrl(endpoint) {
    return this.getApiBaseUrl() + (endpoint.startsWith('/') ? endpoint : '/' + endpoint);
  }
};

// Exportar configuración para uso global
const API_BASE = window.APP_CONFIG.getApiBaseUrl();
console.log('🔧 API Base URL configurada:', API_BASE);