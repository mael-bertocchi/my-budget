# Build stage
FROM node:24-alpine AS builder

# Set the working directory
WORKDIR /app

# Copy package.json and lock file
COPY package*.json ./

# Install dependencies
RUN npm ci --include=dev

# Copy the rest of the code
COPY . .

# Build the application
RUN npm run build

# Production stage
FROM caddy:alpine

# Copy the built files to Caddy's web root
COPY --from=builder /app/dist /usr/share/caddy

# Copy your Caddyfile config
COPY .docker/Caddyfile /etc/caddy/Caddyfile
