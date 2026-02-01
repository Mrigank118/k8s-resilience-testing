FROM nginx:alpine

# Remove default nginx config (optional but clean)
RUN rm -rf /usr/share/nginx/html/*

# Copy frontend files
COPY . /usr/share/nginx/html

# Expose nginx port
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
