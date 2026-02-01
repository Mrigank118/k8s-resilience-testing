FROM node:20-alpine

# Set working directory
WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm install --production

# Copy source code
COPY src ./src

# Create data directory for SQLite (mounted later)
RUN mkdir -p /app/data

# Environment variables
ENV PORT=3000
ENV DB_DIR=/app/data

# Expose backend port
EXPOSE 3000

# Start server
CMD ["node", "src/server.js"]
