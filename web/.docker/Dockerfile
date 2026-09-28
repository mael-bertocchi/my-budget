# --- Builder Stage ---
FROM node:24-alpine AS builder

# Set the working directory
WORKDIR /app

# Copy package.json and lock file
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy the rest of the code
COPY . .

# Build the application
RUN npm run build

# --- Production Stage ---
FROM nginxinc/nginx-unprivileged:alpine

# Copy the server configuration, rendered from the template with API_URL on startup
COPY .docker/nginx/security-headers.conf /etc/nginx/snippets/security-headers.conf
COPY .docker/nginx/default.conf.template /etc/nginx/templates/default.conf.template

# Copy the built application
COPY --from=builder /app/dist /usr/share/nginx/html

# The backend every /v1 request is forwarded to, without a trailing slash
ENV API_URL=https://my-budget.mael-bertocchi.fr

# Serve on an unprivileged port
EXPOSE 8080
