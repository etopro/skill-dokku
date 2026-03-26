#!/usr/bin/bash
# dokku-ssl.sh - Enable Let's Encrypt SSL for a Dokku app
# Usage: ./dokku-ssl.sh <hostname> <appname> <email>

set -euo pipefail

HOSTNAME="$1"
APPNAME="$2"
EMAIL="$3"

if [[ -z "$HOSTNAME" ]] || [[ -z "$APPNAME" ]] || [[ -z "$EMAIL" ]]; then
  echo "Usage: $0 <hostname> <appname> <email>"
  echo "Example: $0 dokku.example.com myadmin admin@example.com"
  exit 1
fi

echo "Configuring Let's Encrypt for $APPNAME..."

# Install letsencrypt plugin if not present
ssh "root@$HOSTNAME" "dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git" || true

# Set email for certificate
ssh "root@$HOSTNAME" "dokku config:set --no-restart $APPNAME DOKKU_LETSENCRYPT_EMAIL=$EMAIL"

# Enable certificate
ssh "root@$HOSTNAME" "dokku letsencrypt:enable $APPNAME"

echo "SSL enabled for $APPNAME"
