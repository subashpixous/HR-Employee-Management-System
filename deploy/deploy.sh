#!/usr/bin/env bash
# ============================================================
# Server-side deploy for the HR Portal (run on the EC2 host).
# Invoked by the GitHub Actions SSH step, or manually:
#   cd /home/ubuntu/app && ./deploy.sh
# Requires: docker-compose.yml, nginx/default.conf and .env in /home/ubuntu/app.
# ============================================================
set -euo pipefail

APP_DIR=/home/ubuntu/app
cd "$APP_DIR"

if [ ! -f .env ]; then
  echo "ERROR: .env not found in $APP_DIR. Copy .env.example to .env and fill it in."
  exit 1
fi

echo "==> [1/5] Pulling latest images from Docker Hub"
docker compose pull

echo "==> [2/5] Stopping current stack"
docker compose down --remove-orphans

echo "==> [3/5] Pruning dangling images"
docker image prune -f

echo "==> [4/5] Starting stack"
docker compose up -d

echo "==> [5/5] Container status"
sleep 5
docker compose ps

echo "==> Backend readiness probe"
backend_up=false
for i in $(seq 1 60); do
  if docker compose exec -T backend curl -fsS http://localhost:7060/v3/api-docs >/dev/null 2>&1; then
    echo "Backend is UP."
    backend_up=true
    break
  fi
  echo "   waiting for backend... ($i/60)"
  sleep 5
done

if [ "$backend_up" != "true" ]; then
  echo "ERROR: backend did not become ready within 5 minutes. Recent logs:"
  docker compose logs --tail 50 backend || true
  exit 1
fi

echo "==> Deploy complete."
