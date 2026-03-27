# Dokku Management Skill

An AI skill for deploying and managing [Dokku](https://dokku.com/) on Linux VMs.

## Overview

Dokku is a mini-Heroku powered by Docker. This skill helps automate the deployment and management of Dokku instances through SSH commands.

---

## AI Agent Guidance

### What the AI Can Do Autonomously

- Install/upgrade Dokku
- Create, list, and destroy apps
- Generate SSH deploy keys
- Deploy from public git repositories
- Set environment variables (once values are provided)
- Restart, rebuild, and scale apps
- View logs, app status, and resource usage
- Install and configure plugins
- Enable SSL (once domain/email are provided)
- Create and mount storage volumes

### What Requires User Input

| Information | Purpose |
|-------------|---------|
| Server hostname/IP | SSH connection |
| App name | Creating/destroying apps |
| Git repository URL | Deploying from git |
| Branch name | Deploying specific branch |
| Environment variable values | App configuration |
| Domain name | SSL, custom routing |
| Email address | Let's Encrypt notifications |
| Personal access tokens | Private repo auth (PAT method) |
| Data volume mount path | Persistent storage (default: /app/data) |
| Confirmation | Destructive operations (destroy servers/apps) |

### Workflow Pattern

1. **Ask** for required information (repo URL, app name, storage needs, etc.)
2. **Execute** the operation autonomously
3. **Report** results and provide URLs/credentials
4. **Confirm** before destructive actions

## Requirements

- **OS**: Ubuntu 22.04/24.04 or Debian 11+ (x64 or arm64)
- **Memory**: 1GB minimum (Docker scheduler), 2GB+ recommended
- **Architecture**: AMD64 (x86_64) or arm64
- **SSH**: Root or sudo access
- **Domain**: Optional but recommended (A record or wildcard, or use sslip.io)

---

## Installation & Upgrade

### Install Dokku

Follow the official installation guide at https://dokku.com/docs/getting-started/installation/

**Important:** The bootstrap URL must be versioned - the generic URL returns 404.

```bash
# Option 1: Install specific version
wget -NP . https://dokku.com/install/v0.37.7/bootstrap.sh
sudo DOKKU_TAG=v0.37.7 bash bootstrap.sh

# Option 2: Install latest version automatically
LATEST_VERSION=$(curl -s https://api.github.com/repos/dokku/dokku/releases/latest | jq -r '.tag_name')
wget -NP . "https://dokku.com/install/$LATEST_VERSION/bootstrap.sh"
sudo "DOKKU_TAG=$LATEST_VERSION" bash bootstrap.sh
```

### Upgrade Dokku

To upgrade to a new version, re-run the bootstrap script with the target version:

```bash
wget -NP . https://dokku.com/install/v0.37.7/bootstrap.sh
sudo DOKKU_TAG=v0.37.7 bash bootstrap.sh
```

---

## Initial Configuration

### SSH Key Setup

```bash
# Add your SSH key for dokku admin access
cat ~/.ssh/authorized_keys | sudo dokku ssh-keys:add admin
```

### Global Domain

```bash
# Set global domain (use your domain, server IP, or sslip.io)
dokku domains:set-global your-domain.com
dokku domains:set-global 10.0.0.2.sslip.io

# View global domain
dokku domains:report --global
```

---

## Management Commands

### App Management

```bash
# Create an app
dokku apps:create myapp

# List all apps
dokku apps:list

# Destroy an app (with confirmation)
dokku apps:destroy myapp

# Destroy an app (force, no confirmation)
dokku apps:destroy myapp --force
```

### Environment Variables (Config)

```bash
# Set config vars (one or more)
dokku config:set myapp NODE_ENV=production DEBUG=false

# View all config vars for an app
dokku config myapp

# Get a single config var
dokku config:get myapp NODE_ENV

# Unset a config var
dokku config:unset myapp DEBUG
```

**Important:** `config:set` automatically restarts the app. Do NOT run `ps:restart` after setting config vars - this would cause a double restart.

#### Managing Environment Variables Across Instances

```bash
# Compare config between two apps
diff <(dokku config app1) <(dokku config app2)

# Copy config from one app to another (use --merged flag)
dokku config:export app1 --merged | dokku config:import app2

# Export all config to file (outputs shell export format)
dokku config:export myapp > myapp-config.env

# Import config from file (requires VAR=value format, not export format)
# Note: Exported files use 'export VAR=value' format. For import, either:
# 1. Use the --merged pipe method above, or
# 2. Process the file to remove 'export ' prefix before importing
dokku config:import myapp < myapp-config.env
```

#### Viewing Environment Variables

```bash
# View all vars for an app
dokku config myapp

# View specific var with --global flag
dokku config:get --global DOKKU_SCALE

# View config report for all apps
dokku config:report --all
```

### Domain Management

```bash
# View global domains
dokku domains:report --global

# View app domains
dokku domains:report myapp

# Add domain to app
dokku domains:add myapp www.example.com

# Remove domain from app
dokku domains:remove myapp www.example.com

# Reset app domains to global defaults
dokku domains:reset myapp
```

### Service Control

```bash
# Restart nginx (proxy)
systemctl restart nginx

# Restart docker
systemctl restart docker

# Check service status
systemctl status nginx
systemctl status docker
systemctl is-active nginx
```

---

## Testing & Verification

After installation or upgrade, verify everything works:

```bash
# Check Dokku version
dokku version

# List installed plugins
dokku plugin:list

# Verify services are running
systemctl is-active nginx docker

# Check listening ports
ss -tlnp | grep -E ':(80|443|22)'

# Create test app, verify, then delete
dokku apps:create test-app
dokku apps:list
dokku apps:destroy test-app --force
```

### System Report

```bash
# Full system report
dokku report

# Specific report for app
dokku domains:report myapp
dokku config:report myapp
```

---

## Deployment

### Quick Test Deployment (Docker Image)

Fastest way to deploy a test app - directly from a Docker image:

```bash
# Create app
dokku apps:create myapp

# Deploy from public Docker image
dokku git:from-image myapp nginx:alpine

# App will be available at: http://myapp.your-domain.com
```

### Deploy from Git Repository

#### Public Repositories

```bash
# Create app
dokku apps:create myapp

# Allow the git host (adds to known_hosts)
dokku git:allow-host github.com

# Clone and build from remote repo
dokku git:sync --build myapp https://github.com/user/repo.git

# Specify branch/tag
dokku git:sync --build myapp https://github.com/user/repo.git main
```

#### Private Repositories (SSH Key Method)

**Step 1: Generate SSH deploy key**

```bash
# Generate key pair
dokku git:generate-deploy-key

# Display public key (add this to your git host)
dokku git:public-key
```

**Step 2: Add deploy key to git host**

- GitHub: Repo → Settings → Deploy Keys → Add deploy key
- GitLab: Repo → Settings → Repository → Deploy Keys
- Bitbucket: Repo → Settings → Access keys → Add key

**Step 3: Deploy from private repo**

```bash
# Allow the git host
dokku git:allow-host github.com

# Create app
dokku apps:create myapp

# Sync and deploy using SSH URL
dokku git:sync --build myapp git@github.com:user/private-repo.git main
```

#### Private Repositories (Personal Access Token Method)

```bash
# Store credentials for git host
dokku git:auth github.com username personal-access-token

# Deploy using HTTPS URL
dokku git:sync --build myapp https://github.com/user/private-repo.git main

# Remove credentials when done
dokku git:auth github.com
```

### Deploy via Git Push (Traditional)

```bash
# On local machine, add remote
git remote add dokku dokku@your-server:myapp

# Push to deploy
git push dokku main
```

### Manual Update from Repository

To manually update an app from its git repository (useful for pulling latest changes):

```bash
# Sync and rebuild (always rebuilds)
dokku git:sync --build myapp git@github.com:user/repo.git main

# Sync and rebuild only if changes detected
dokku git:sync --build-if-changes myapp git@github.com:user/repo.git main
```

**Note:** `--build-if-changes` is efficient for periodic checks - it only rebuilds if the repository has new commits.

### Logs

```bash
# View app logs
dokku logs myapp

# Tail logs (follow)
dokku logs myapp -t

# View last 100 lines
dokku logs myapp -n 100
```

### Process Management

```bash
# Restart app
dokku ps:restart myapp

# Rebuild app (without git push)
dokku ps:rebuild myapp

# Scale processes
dokku ps:scale myapp web=2 worker=1

# View running processes
dokku ps:report myapp

# View all running containers
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

### Resource Monitoring

**Important:** When user asks about resource usage, report BOTH overall VM stats AND per-container stats.

```bash
# === Overall VM Resources ===
# Memory usage
free -h

# Disk usage
df -h /

# CPU info
nproc
cat /proc/meminfo | grep MemTotal

# === Per-Container Resources ===
# Container resource usage (CPU, memory, %)
docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}'

# Container status with uptime
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

# === Storage/Mount Disk Usage ===
# Check app storage mount disk usage
du -sh /var/lib/dokku/data/storage/*

# List all storage mounts for an app
dokku storage:list myapp

# View storage report
dokku storage:report myapp
```
docker stats
```

---

## Storage & Persistent Data

### Understanding App Data

Dokku maintains app data in `/home/dokku/<appname>/`:
- **Git repository** (~400 KB) - Cloned source code, deployment metadata
- **Config files** - ENV, domains, nginx configuration
- **Logs** - Git operation logs

This data is **NOT** mounted in containers - it's Dokku's bookkeeping only.

### Persistent Storage (Volumes)

For data that must persist across deployments (databases, uploads), use bind mounts:

```bash
# Create a persistent storage directory
dokku storage:ensure-directory /var/lib/dokku/data/storage/myapp

# Mount storage to app (host:container)
dokku storage:mount myapp /var/lib/dokku/data/storage/myapp:/app/data

# List all mounts for an app
dokku storage:list myapp

# View storage report
dokku storage:report myapp

# Unmount storage
dokku storage:unmount myapp /var/lib/dokku/data/storage/myapp:/app/data
```

### Checking Disk Usage

```bash
# View overall disk usage
df -h

# View Docker disk usage (images, containers, build cache)
docker system df

# View per-app data directory size
du -sh /home/dokku/*/

# View image sizes for apps
docker images --format 'table {{.Repository}}\t{{.Size}}' | grep dokku/
```

### App Data Directory Contents

```
/home/dokku/myapp/
├── objects/       # Git objects (source code)
├── refs/          # Git references (branches, tags)
├── hooks/         # Git hooks
├── config/        # App configuration files
├── nginx.conf     # Proxy configuration
└── ENV            # Environment variables (shipped to container)
```

---

## Multiple Instances

### Deploying Multiple Instances of the Same App

You can run multiple instances of the same codebase with different configurations:

```bash
# Deploy first instance
dokku apps:create myapp-prod
dokku config:set myapp-prod API_KEY=prod_key ENV=production
dokku git:sync --build myapp-prod git@github.com:user/repo.git main

# Deploy second instance (staging)
dokku apps:create myapp-staging
dokku config:set myapp-staging API_KEY=staging_key ENV=staging
dokku git:sync --build myapp-staging git@github.com:user/repo.git main
```

Each instance gets:
- Unique subdomain: `myapp-prod.domain.com`, `myapp-staging.domain.com`
- Isolated environment variables
- Separate Docker containers

### Managing Multiple Instances

```bash
# List all apps
dokku apps:list

# View status of all running containers
docker ps --format 'table {{.Names}}\t{{.Status}}'

# View logs for specific instance
dokku logs myapp-prod

# Restart specific instance
dokku ps:restart myapp-staging

# Compare config between instances
dokku config myapp-prod
dokku config myapp-staging
```

### Instance Naming Conventions

Recommended patterns:
- By environment: `myapp-prod`, `myapp-staging`, `myapp-dev`
- By region: `myapp-eu`, `myapp-us`, `myapp-asia`
- By client: `myapp-client1`, `myapp-client2`
- By purpose: `myapp-worker`, `myapp-api`, `myapp-web`

---

## SSL & Certificates

### Let's Encrypt (Automatic SSL)

Install the Let's Encrypt plugin for free automatic SSL certificates:

```bash
# Install the plugin
dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git

# Set global email for certificate notifications
dokku letsencrypt:set --global email your-email@example.com

# Enable SSL for an app
dokku letsencrypt:enable myapp

# Check if SSL is active
dokku letsencrypt:active myapp

# List all apps with SSL certificates and expiry
dokku letsencrypt:list
```

**Important:** The app's domain must have valid DNS pointing to your server IP before enabling Let's Encrypt.

### Certificate Management

```bash
# View certificate details and expiry
dokku certs:report myapp

# Manually renew a certificate
dokku letsencrypt:auto-renew myapp

# Revoke a certificate
dokku letsencrypt:revoke myapp

# Disable SSL for an app
dokku letsencrypt:disable myapp
```

### Auto-Renewal Setup

Let's Encrypt certificates are valid for 90 days. Set up automatic renewal:

```bash
# Add cron job for auto-renewal (runs daily)
dokku letsencrypt:cron-job --add

# Remove cron job
dokku letsencrypt:cron-job --remove
```

### Custom SSL Certificates

If you have your own SSL certificate:

```bash
# Install custom certificate
dokku certs:add myapp /path/to/cert.crt /path/to/cert.key

# Remove certificate
dokku certs:remove myapp
```

---

## Troubleshooting

### Common Issues

**Conflict errors during deployment**
```
telegram.error.Conflict: Conflict: terminated by other getUpdates request
```
This is **expected** during zero-downtime deployments when old and new containers briefly overlap. It resolves automatically once the old container shuts down (60 seconds).

**Locale warnings**
```
perl: warning: Setting locale failed
```
Harmless warnings. To fix:
```bash
sudo apt update && sudo apt install -y locales
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8
```

**Storage directory creation fails with hyphens**
```bash
# This may fail if app name contains hyphens:
dokku storage:ensure-directory /var/lib/dokku/data/storage/my-app

# Use mkdir instead:
mkdir -p /var/lib/dokku/data/storage/my-app
dokku storage:mount my-app /var/lib/dokku/data/storage/my-app:/app/data
```

**App won't start after deployment**
```bash
# Check logs
dokku logs myapp -n 100

# Check container status
docker ps -a | grep myapp

# Restart app
dokku ps:restart myapp
```

---

## App Lifecycle Management

### Starting, Stopping, Restarting

```bash
# Start a stopped app
dokku ps:start myapp

# Stop a running app (containers removed, data preserved)
dokku ps:stop myapp

# Restart app (zero-downtime redeploy)
dokku ps:restart myapp

# Rebuild app (without git push)
dokku ps:rebuild myapp

# Check app status
dokku ps:report myapp
```

**Important:**
- `ps:stop` - Stops containers, persistent data remains
- `ps:restart` - Zero-downtime restart (new container starts before old stops)
- `ps:rebuild` - Rebuilds image from existing code

---

## Docker Cleanup

Old containers and images accumulate over time. Clean up periodically:

```bash
# Remove all stopped containers
docker container prune -f

# Remove unused images (not used by any container)
docker image prune -a -f

# View disk usage before cleanup
docker system df

# Full system cleanup (includes build cache)
docker system prune -a -f
```

**Warning:** Be careful with `docker volume prune` - it can remove data. Use `dokku storage:list` to identify app volumes first.

---

## Zero-Downtime Deployments

Dokku supports zero-downtime deployments with healthchecks. Without healthchecks, Dokku uses simple container uptime checks.

### Adding Healthchecks

Create `app.json` in your repo:

```json
{
  "formation": {
    "web": {
      "quantity": 1
    }
  },
  "healthchecks": [
    {
      "name": "alive",
      "type": "startup",
      "path": "/health",
      "attempts": 3
    }
  ]
}
```

### Healthcheck Behavior

- **Without healthchecks**: 10-second uptime check + port listening check
- **With healthchecks**: Custom checks defined in app.json

```bash
# Test healthcheck endpoint
curl http://myapp.domain.com/health
```

---

## Backup & Restore

### App Backup Checklist

1. **Environment variables**
   ```bash
   dokku config:export myapp > myapp-config.env
   ```

2. **App data (storage mounts)**
   ```bash
   # Check what's mounted
   dokku storage:list myapp

   # Backup storage directory
   tar -czf myapp-storage.tar.gz /var/lib/dokku/data/storage/myapp
   ```

### Restore Procedure

```bash
# 1. Create app
dokku apps:create myapp

# 2. Import config
dokku config:import myapp < myapp-config.env

# 3. Restore storage
tar -xzf myapp-storage.tar.gz -C /

# 4. Deploy
git push dokku main
```

---

## Resources

- [Dokku Documentation](https://dokku.com/docs/)
- [Dokku GitHub](https://github.com/dokku/dokku)
- [Installation Guide](https://dokku.com/docs/getting-started/installation/)
