#!/usr/bin/bash
# dokku-app-create.sh - Create a new Dokku app with optional domain
# Usage: ./dokku-app-create.sh <hostname> <appname> [domain]

set -euo pipefail

HOSTNAME="$1"
APPNAME="$2"
DOMAIN="${3:-}"

if [[ -z "$HOSTNAME" ]] || [[ -z "$APPNAME" ]]; then
  echo "Usage: $0 <hostname> <appname> [domain]"
  echo "Example: $0 dokku.example.com myapp myapp.example.com"
  exit 1
fi

echo "Creating app: $APPNAME"

ssh "root@$HOSTNAME" "dokku apps:create $APPNAME"

if [[ -n "$DOMAIN" ]]; then
  echo "Setting domain: $DOMAIN"
  ssh "root@$HOSTNAME" "dokku domains:set $APPNAME $DOMAIN"
fi

echo "App $APPNAME created successfully"
echo "Deploy with: git remote add dokku dokku@$HOSTNAME:$APPNAME"
