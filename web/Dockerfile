# syntax=docker/dockerfile:1

# ============================================================
# Stage 1 — build the static SPA (Vite)
# ============================================================
FROM node:20-alpine AS build
WORKDIR /app
ENV CI=true

# Same-origin API base by default: empty => the app calls "/api" and "/ws",
# which the reverse proxy forwards to the backend. Override at build time if
# you serve the API from a different host.
ARG VITE_API_URL=""
ENV VITE_API_URL=$VITE_API_URL

COPY package.json package-lock.json ./
# npm can miss the Linux rollup optional binary when the lockfile was generated
# on Windows/macOS; fall back to a clean install so `vite build` succeeds.
RUN npm ci --no-audit --no-fund || (rm -f package-lock.json && npm install --no-audit --no-fund)

COPY . .
RUN npm run build

# ============================================================
# Stage 2 — serve the built assets with nginx
# ============================================================
FROM nginx:1.27-alpine AS runtime

# SPA routing (history fallback) for this container's internal nginx.
COPY docker/nginx-spa.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -q --spider http://localhost/ || exit 1
