# syntax=docker/dockerfile:1

# Base stage with common dependencies
FROM node:22-slim AS base
WORKDIR /app
RUN apt-get update && apt-get install -y curl git python3 make g++ build-essential

# Build stage
FROM base AS builder
# Copy package files
COPY package*.json ./
# Always generate package-lock.json, then use npm ci for deterministic installs
RUN npm install --package-lock-only && npm ci
# Copy source code
COPY . .
# Build the application using the tsup build script
RUN npm run build

# Development stage
FROM base AS development
# Copy package files
COPY package*.json ./
# Always generate package-lock.json, then use npm ci for deterministic installs
RUN npm install --package-lock-only && npm ci
# Verify that ts-node is installed for the start script
RUN npm list ts-node || npm install -g ts-node
# Copy source code
COPY . .
# Expose ports
EXPOSE 4400 4401 4490 4491
# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:4491/health || exit 1
# Start using the start script instead of dev
CMD ["npm", "run", "start"]

# Production stage
FROM base AS production
# Copy package files
COPY package*.json ./
# Copy package-lock.json from builder stage
COPY --from=builder /app/package-lock.json ./
# Install only production dependencies
RUN npm ci --omit=dev
# Copy built files from builder
COPY --from=builder /app/dist ./dist
# Expose ports (4400: Main API, 4401: WebSocket, 4490: Metrics, 4491: Health)
EXPOSE 4400 4401 4490 4491
# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:4491/health || exit 1
# Set environment variables to skip problematic features
ENV ELIZA_DISABLE_EMBEDDINGS=true
ENV ELIZA_DISABLE_LLM=true
ENV ELIZA_MINIMAL_MODE=true
# Start the application using the built files
CMD ["node", "dist/index.js"]