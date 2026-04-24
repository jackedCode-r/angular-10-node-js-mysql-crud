# ──────────────────────────────────────────
# Stage 1 — Build Angular App
# ──────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files first — better layer caching
# Docker won't re-run npm ci unless package.json changes
COPY package*.json ./

# npm ci = clean install, faster, strict lockfile
RUN npm ci

# Copy rest of source code
COPY . .

# Build for production
RUN npm run build --configuration=production

# ──────────────────────────────────────────
# Stage 2 — Serve with Nginx
# ──────────────────────────────────────────
FROM nginx:alpine

# Remove default nginx page
RUN rm -rf /usr/share/nginx/html/*

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Add our custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built Angular files from Stage 1
# ⚠️ Replace 'your-app-name' with your actual angular app name
# Check your angular.json → projects → [name] to confirm
COPY --from=builder /app/dist/Angular10Crud/browser /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
    CMD wget -qO- http://localhost:80 || exit 1

CMD ["nginx", "-g", "daemon off;"]
