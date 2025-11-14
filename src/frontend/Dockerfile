# Use nginx alpine for smaller image
FROM nginx:alpine

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy nginx configuration first
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy frontend files (exclude nginx config and dockerfile)
COPY --chown=nginx:nginx *.html /usr/share/nginx/html/
COPY --chown=nginx:nginx *.css /usr/share/nginx/html/
COPY --chown=nginx:nginx js/ /usr/share/nginx/html/js/

# Set proper permissions
RUN chown -R nginx:nginx /usr/share/nginx/html

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1

# Expose port
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
