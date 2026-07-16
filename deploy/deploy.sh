#!/usr/bin/env bash
# ============================================================
# Server-side deploy for the HR Portal (run on the EC2 host).
# Invoked by the GitHub Actions SSH step, or manually:
#   cd ~/hr-portal && ./deploy.sh
# Requires: docker-compose.yml, nginx/default.conf and .env in this directory.
# ============================================================
set -euo pipefail
cd "$(dirname "$0")"

if [ ! -f .env ]; then
  echo "ERROR: .env not found in $(pwd). Copy .env.example to .env and fill it in."
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
for i in $(seq 1 30); do
  if docker compose exec -T backend curl -fsS http://localhost:7060/v3/api-docs >/dev/null 2>&1; then
    echo "Backend is UP."
    break
  fi
  echo "   waiting for backend... ($i/30)"
  sleep 5
done

echo "==> Deploy complete."
