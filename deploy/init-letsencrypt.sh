#!/usr/bin/env bash
# ============================================================
# One-time Let's Encrypt certificate bootstrap for the reverse proxy.
# Prereqs: DNS A-record points at this EC2 host, ports 80/443 open,
# and the stack is already running (docker compose up -d).
#
#   ./init-letsencrypt.sh your-domain.com you@example.com
#
# After it succeeds, enable the :443 server block in nginx/default.conf
# (replace <your-domain>), then: docker compose restart nginx
# ============================================================
set -euo pipefail
cd "$(dirname "$0")"

DOMAIN="${1:-}"
EMAIL="${2:-}"
if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
  echo "Usage: ./init-letsencrypt.sh <domain> <email>"
  exit 1
fi

mkdir -p certbot/www certbot/conf

# Ensure the edge nginx is serving the ACME challenge over HTTP.
docker compose up -d nginx

echo "==> Requesting certificate for $DOMAIN"
docker run --rm \
  -v "$PWD/certbot/conf:/etc/letsencrypt" \
  -v "$PWD/certbot/www:/var/www/certbot" \
  certbot/certbot certonly --webroot -w /var/www/certbot \
  -d "$DOMAIN" --email "$EMAIL" --agree-tos --no-eff-email --non-interactive

echo "==> Certificate issued."
echo "    Next: uncomment/adjust the :443 block in nginx/default.conf, then"
echo "          docker compose restart nginx"
echo "    Renewal (add to crontab):"
echo "      0 3 * * * cd $(pwd) && docker run --rm -v \$PWD/certbot/conf:/etc/letsencrypt -v \$PWD/certbot/www:/var/www/certbot certbot/certbot renew --webroot -w /var/www/certbot && docker compose restart nginx"
