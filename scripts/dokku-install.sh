#!/usr/bin/bash
# dokku-install.sh - Bootstrap Dokku on a fresh Ubuntu/Debian VM
# Usage: ./dokku-install.sh [hostname]

set -euo pipefail

HOSTNAME="${1:-}"
SSH_USER="${SSH_USER:-root}"

if [[ -z "$HOSTNAME" ]]; then
  echo "Usage: $0 <hostname>"
  echo "Example: $0 dokku.example.com"
  exit 1
fi

echo "Installing Dokku on $HOSTNAME..."

# Install Dokku bootstrap script
ssh "$SSH_USER@$HOSTNAME" bash -c "
  wget -NP . https://dokku.com/install/v0.35.8/bootstrap.sh
  sudo DOKKU_TAG=v0.35.8 bash bootstrap.sh
"

echo "Dokku installed. Visit http://$HOSTNAME to complete setup."
