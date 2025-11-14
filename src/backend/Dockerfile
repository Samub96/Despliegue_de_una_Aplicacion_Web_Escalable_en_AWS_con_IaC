# Use Node.js Alpine for smaller image
FROM node:18-alpine

# Install build dependencies for native modules (including bcrypt)
RUN apk add --no-cache python3 make g++ libc6-compat

# Create app user for security
RUN addgroup -g 1001 -S nodejs && adduser -S appuser -u 1001 -G nodejs

# Set working directory
WORKDIR /app

# Copy package files first (for better layer caching)
COPY package*.json ./

# Remove any existing node_modules and package-lock to force fresh install
RUN rm -rf node_modules package-lock.json

# Install dependencies fresh (this will compile bcrypt for Alpine Linux)
RUN npm install --only=production

# Copy application code (node_modules is excluded via .dockerignore)
COPY . .

# Change ownership to non-root user
RUN chown -R appuser:nodejs /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD node -e "require('http').get('http://localhost:8080', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Start application
CMD ["node", "server.js"]
