# Stage 1 - Install dependencies
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

# Stage 2 - Production image
FROM node:20-alpine

WORKDIR /app

# Non-root user (security best practice)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy only production deps from builder
COPY --from=builder /app/node_modules ./node_modules
COPY . .

# Give ownership to non-root user
RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "server.js"]
