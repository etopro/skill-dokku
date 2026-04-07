# Dokku Management Skill

An AI skill for deploying and managing [Dokku](https://dokku.com/) on Linux VMs.

## Overview

Dokku is a mini-Heroku powered by Docker. This skill helps automate the deployment and management of Dokku instances through SSH commands.

---

## AI Agent Guidance

### First-Time Users — Onboarding

**If the user has NOT provided a server IP address and appears to be a new Dokku user:**

1. Suggest running `/dokku-onboarding` for an interactive guided introduction
2. The onboarding skill will: show ASCII dashboard, collect server info, teach basic commands
3. If user declines, proceed with normal Dokku operations below

**If the user HAS provided a server IP or is a returning user:** skip onboarding and go directly to operations.

---

### What the AI Can Do Autonomously

- Install/upgrade Dokku
- Create, list, and destroy apps
- Generate SSH deploy keys
- Deploy from public git repositories
- Set environment variables (once values are provided)
- Restart, rebuild, and scale apps
- View logs, app status, and resource usage
- Install and configure plugins
- **Detect service type (public vs internal) and proactively offer SSL setup**
- Enable SSL with Let's Encrypt (once domain/email are provided)
- Configure healthchecks for public services
- Enable automatic certificate renewal
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

### SSH Command Security Patterns

**CRITICAL:** When running commands via SSH, avoid these patterns that trigger security prompts:

| ❌ Avoid | ✅ Use Instead |
|---------|---------------|
| `ssh host "echo '---' && cmd"` | Run commands separately |
| `ssh host " --flag value"` | `ssh host "cmd --flag value"` (no empty quotes/leading space before `--`) |
| `ssh host "$(subcommand)"` | Run subcommand separately |

**Rules:**
1. Don't chain commands with `echo` for formatting - run commands separately
2. Don't use empty quotes or leading space before flags (e.g., `"--flag"` at start)
3. Don't use command substitution `$(...)` inside SSH commands

**Correct pattern:**
```bash
ssh root@server "dokku apps:list"
ssh root@server "docker stats --no-stream"
ssh root@server "free -h"
```

### Workflow Pattern

1. **Ask** for required information (repo URL, app name, storage needs, etc.)
2. **Execute** the operation autonomously
3. **Report** results and provide URLs/credentials
4. **Confirm** before destructive actions

### Service Type Detection (CRITICAL FOR PUBLIC SERVICES)

**Early in deployment, detect whether this is a public or internal service:**

```
Will this service be accessed by external users/customers?
- YES → Public web service (customers/users access it from internet)
- NO  → Internal application (team only, no external access, internal bots)
```

**Public Services → Automatic Recommendations:**

After deployment, proactively suggest:

1. **🔒 SSL/HTTPS Setup** (CRITICAL)
   - Let's Encrypt (free, auto-renewal)
   - Email for renewal notifications
   - DNS must be configured pointing to server

2. **💚 Healthchecks** (for zero-downtime deployments)
   - Automatic app health verification
   - Prevents broken deploys

3. **🔄 Auto-Renewal** (prevents certificate expiry)
   - SSL certs expire every 90 days
   - Must be auto-renewed or app breaks

**Internal Applications → Minimal Setup:**
- Skip SSL setup questions
- Deploy directly without SSL/HTTPS setup prompts
- Offer storage/config only if needed

**Key Decision Logic:**

```
Is this a public web service?
├─ YES (customers/users access from internet)
│  ├─ Recommend SSL immediately
│  ├─ Ask for email + DNS readiness
│  ├─ Enable healthchecks
│  └─ Enable auto-renewal
│
└─ NO (internal use only)
   ├─ Deploy with minimal questions
   ├─ Skip SSL setup
   └─ Offer advanced features on request
```

## Requirements

- **OS**: Ubuntu 22.04/24.04 or Debian 11+ (x64 or arm64)
- **Memory**: 1GB minimum (Docker scheduler), 2GB+ recommended
- **Architecture**: AMD64 (x86_64) or arm64
- **SSH**: Root or sudo access
- **Domain**: Optional but recommended (A record or wildcard, or use sslip.io)

---

## Remote Server Access

All Dokku commands are run via SSH on the remote server.

### Interactive SSH Session

```bash
# Connect to your Dokku server
ssh root@your-server-ip

# Once connected, run dokku commands directly
dokku apps:list
dokku logs myapp
dokku ps:report myapp
```

### Single Command (Non-Interactive)

Execute a single command without entering an interactive session:

```bash
# Pattern: ssh user@host "dokku command"
ssh root@46.225.99.67 "dokku apps:list"
ssh root@46.225.99.67 "dokku config:set myapp KEY=value"
ssh root@46.225.99.67 "dokku logs myapp -n 50"
```

Use this pattern for automation, scripts, and when you need command output for further processing.

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
sudo DOKKU_TAG=$LATEST_VERSION bash bootstrap.sh
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

### Checking Deploy Source & App Configuration

See where an app is deployed from and how it was built:

```bash
# View full app report (includes deploy source, metadata, and more)
dokku apps:report <app-name>

# Shows deploy method and source:
# - App deploy source: git-sync | docker-image | git
# - App deploy source metadata: <repo-url>#<commit> or <image-name>

# Examples:
# git-sync:   git@github.com:user/repo.git#0cbd4c7d3d00ad7436df14412064b8f33255cbe2
# git-sync:   https://github.com/user/repo.git#447ec7c69c9d5b884ee2c9fe2da26729122d5163
# docker-image: nginx:alpine
# docker-image: ollama/ollama

# Check all apps' deploy sources
for app in $(dokku apps:list | tail -n +2); do
  echo "=== $app ==="
  dokku apps:report $app | grep -E '(deploy source|metadata)'
done

# Quick check for single app
dokku apps:report <app-name> | grep -E deploy
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

**Important:** `config:set` and `config:unset` automatically restart the app. Use `--no-restart` to prevent this (useful when setting multiple vars in sequence). Do NOT run `ps:restart` after setting config vars - this would cause a double restart.

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
```

---

## Deployment

### CRITICAL: Determine Service Type FIRST

**Before any deployment, determine the service type using the**
[Service Type Detection](#service-type-detection-critical-for-public-services)
**guidance in the AI Agent Guidance section.**

**Why this matters:**
- Public services WITHOUT SSL = data exposed, browser warnings, client rejection
- Public services WITHOUT auto-renewal = broken in 90 days
- Treating public services as internal = security/reliability issues

---

### Quick Test Deployment (Docker Image)

Fastest way to deploy a test app - directly from a Docker image:

```bash
# Create app
dokku apps:create myapp

# Deploy from public Docker image
dokku git:from-image myapp nginx:alpine

# App will be available at: http://myapp.your-domain.com
```

### Deploy from Container Registry

Deploy from GitHub Container Registry (ghcr.io), Docker Hub, or any OCI registry:

```bash
# Create app
dokku apps:create myapp

# Deploy from GitHub Container Registry
dokku git:from-image myapp ghcr.io/org/app:latest

# Deploy from Docker Hub (official images)
dokku git:from-image myapp ollama/ollama

# Deploy from Docker Hub (with tag)
dokku git:from-image myapp postgres:16-alpine

# Deploy from custom registry
dokku git:from-image myapp registry.example.com/team/app:v1.2.3
```

**After deploying a registry image**, verify the app is working:

```bash
# Check container is running
docker ps --format 'table {{.Names}}\t{{.Status}}' | grep myapp

# Check what port the app actually listens on (see Port Discovery below)
docker exec myapp.web.1 ss -tlnp 2>/dev/null || docker exec myapp.web.1 netstat -tlnp 2>/dev/null

# Check logs for startup errors
dokku logs myapp -n 50
```

**Important:** Registry images often listen on non-standard ports. Dokku auto-detects ports from `EXPOSE` in the Dockerfile, but this may not match the actual listening port. Always verify and fix port mappings after deploying — see [Port Discovery](#port-discovery-for-new-apps).

### Deploy from Git Repository

**Important:** `git:sync` with HTTPS URLs works for **public repos** — just make sure to specify the branch (e.g., `main`), as the default branch detection may fail if the repo doesn't use `master`. For **private repos**, HTTPS prompts for credentials and doesn't work non-interactively — use SSH URLs with deploy keys instead.

#### Public Repositories (via git push)

```bash
# On local machine, add remote
git remote add dokku dokku@your-server:myapp

# Push to deploy
git push dokku main
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

### Manual Update from Repository

For traditional `git push` deploys from your local machine, see [Public Repositories (via git push)](#public-repositories-via-git-push) above.

To manually update an app on the server from its git repository (useful for pulling latest changes):

```bash
# Sync and rebuild (always rebuilds)
dokku git:sync --build myapp git@github.com:user/repo.git main

# Sync and rebuild only if changes detected
dokku git:sync --build-if-changes myapp git@github.com:user/repo.git main
```

**Note:** `--build-if-changes` is efficient for periodic checks - it only rebuilds if the repository has new commits.

### Dockerfile Deployment Options

When deploying from a Dockerfile, you can customize the runtime command without modifying the source repository:

#### Override the Container Command

Use `DOKKU_DOCKERFILE_START_CMD` to override the `CMD` or pass parameters to `ENTRYPOINT`:

```bash
# Override the CMD from Dockerfile
dokku config:set myapp DOKKU_DOCKERFILE_START_CMD="gateway"

# Pass parameters to ENTRYPOINT
dokku config:set myapp DOKKU_DOCKERFILE_START_CMD="--harmony server.js"
```

This is useful when:
- The upstream Dockerfile has an incorrect `CMD` (e.g., `status` instead of `gateway`)
- You want to run different commands in different environments
- You need to test a command variant without forking the repo

**Important:** This only affects the runtime command. The build still uses the Dockerfile from the repository.

### Logs

```bash
# View app logs
dokku logs myapp

# Tail logs (follow)
dokku logs myapp -t

# View last 100 lines
dokku logs myapp -n 100
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

# Container creation time
docker ps --format 'table {{.Names}}\t{{.CreatedAt}}'

# App disk usage (data directory)
du -sh /home/dokku/*/

# === Storage/Mount Disk Usage ===
# Check app storage mount disk usage
du -sh /var/lib/dokku/data/storage/*

# === Docker Disk Usage ===
# View Docker disk usage (images, containers, build cache)
docker system df

# View image sizes for apps
docker images --format 'table {{.Repository}}\t{{.Size}}' | grep dokku/
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

**Important:** Always use `/var/lib/dokku/data/storage/<appname>` as the **host path** for consistency. This is Dokku's standard storage location and makes backup and management easier.

```bash
# Create a persistent storage directory (relative to /var/lib/dokku/data/storage/)
dokku storage:ensure-directory myapp

# Mount storage to app (host:container)
dokku storage:mount myapp /var/lib/dokku/data/storage/myapp:/app/data

# List all mounts for an app
dokku storage:list myapp

# View storage report
dokku storage:report myapp

# Unmount storage
dokku storage:unmount myapp /var/lib/dokku/data/storage/myapp:/app/data
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

### FOR PUBLIC SERVICES: SSL IS MANDATORY

**If service type = PUBLIC (external users access it):**
- ✅ Always enable SSL/HTTPS (after determining DNS is ready)
- ✅ Always set up auto-renewal (certificate expires every 90 days)
- ✅ Always ask for email for renewal notifications

**If service type = INTERNAL (team/bots only):**
- Skip SSL setup entirely
- Deploy without these questions

---

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

**Port 80 mapping required:** Let's Encrypt uses HTTP-01 challenge which requires port 80 to be accessible. If the app only listens on a specific port (e.g., 8080), add port 80 mapping first. See [Port Management](#port-management) for details.

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

# Scale processes
dokku ps:scale myapp web=2 worker=1

# Check app status
dokku ps:report myapp

# View all running containers
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

**Important:**
- `ps:stop` - Stops containers, persistent data remains
- `ps:restart` - Zero-downtime restart (new container starts before old stops)
- `ps:rebuild` - Rebuilds image from existing code

### App Locking

Prevent new deployments while performing maintenance or debugging:

```bash
# Lock app (prevents deploys)
dokku apps:lock myapp

# Check if app is locked (exits 0 if locked)
dokku apps:locked myapp

# Unlock app
dokku apps:unlock myapp
```

**Use Cases:**
- **Maintenance** - Prevent deploys during system maintenance
- **Debugging** - Keep running version stable while investigating issues
- **Emergency Freeze** - Stop all deploys during critical periods

**Behavior:**
- Locked apps reject `git push` deployments
- Does **not** stop the app (containers keep running)
- Does **not** stop in-progress deploys
- Manual unlock required to deploy again

---

## Running Commands in Containers

### Enter a Running Container (`dokku enter`)

Open an interactive shell in a running app container for debugging:

```bash
# Enter the web container (opens /bin/bash)
dokku enter myapp

# Enter a specific process type
dokku enter myapp web

# Enter a specific scaled instance
dokku enter myapp web.2

# Enter by container ID
dokku enter myapp --container-id <container-id>

# Run a command without interactive shell
dokku enter myapp web echo "hello"
dokku enter myapp web ls /app
```

**Behavior:**
- Defaults to `/bin/bash` if no command is given
- If the app has only one process type, `dokku enter myapp` connects to it automatically
- For scaled processes, omitting the index connects to the first instance (`.1`)
- This connects to an **existing running** container — no new container is created

### Run One-Off Commands (`dokku run`)

Execute a command in a **new ephemeral container** using the app's image and environment:

```bash
# Run a one-off command
dokku run myapp python manage.py migrate
dokku run myapp rails db:seed
dokku run myapp npm run seed

# Open an interactive shell in a fresh container
dokku run myapp bash

# Pass extra environment variables
dokku run -e DEBUG=true -e LOG_LEVEL=verbose myapp python script.py

# Run without TTY (useful in scripts/automation)
dokku run --no-tty myapp echo "done"

# Run a Procfile-defined command by name
dokku run myapp console
```

**Container lifecycle:**
- One-off containers are **automatically removed** when the process exits
- Default TTL is **24 hours** (86400 seconds) — containers running longer are reaped
- Override TTL: `dokku run --ttl-seconds 3600 myapp long-task.sh`

### Detached One-Off Commands

Run a command in the background:

```bash
# Start detached (returns container name immediately)
dokku run:detached myapp python long_task.py

# List running one-off containers
dokku run:list myapp

# View logs from a one-off container
dokku run:logs myapp
dokku run:logs --container <container-name> -t  # follow/tail

# Stop a one-off container
dokku run:stop myapp
dokku run:stop --container <container-name>
```

### `enter` vs `run` — When to Use Which

| | `dokku enter` | `dokku run` |
|---|---|---|
| Container | Connects to **existing** running container | Creates a **new** ephemeral container |
| Use case | Debugging a live process, inspecting state | Migrations, seeds, one-off scripts |
| Impact on app | Shares resources with running app | Isolated, no impact on running app |
| Cleanup | Nothing to clean up | Container auto-removed on exit |

---

## Network Management

### Network Configuration

Manage how apps bind to network interfaces:

```bash
# View network report for app
dokku network:report myapp

# View global network settings
dokku network:report --global

# Bind app to all interfaces (0.0.0.0)
dokku network:set myapp bind-all-interfaces true

# Disable bind-all-interfaces
dokku network:set myapp bind-all-interfaces false
```

**When to use `bind-all-interfaces`:**
- Not using a reverse proxy (nginx)
- Custom networking setup
- Direct container access

**Note:** Most deployments use the nginx proxy and don't need this setting.

### Inter-Container Networking

By default, Dokku apps run on Docker's `bridge` network, which does **not** support DNS resolution between containers. If one app needs to reach another (e.g., an app calling an Ollama LLM server), you must create a shared Docker network.

```bash
# Create a shared network
dokku network:create shared

# Attach apps to the shared network
dokku network:set app1 attach-post-deploy shared
dokku network:set app2 attach-post-deploy shared

# Redeploy both apps to join the network
dokku ps:rebuild app1
dokku ps:rebuild app2
```

Once on the same custom network, containers can reach each other by name: `http://app2.web.1:port`.

```bash
# Verify connectivity from one container to another
docker exec app1.web.1 curl -s http://app2.web.1:11434/

# View which networks an app is attached to
dokku network:report myapp
```

**Important:**
- Both apps must be redeployed after attaching to the network — the setting only takes effect on deploy.
- The container hostname is `<appname>.web.1` (Dokku's naming convention).
- Apps referencing each other should use the container name in their config, not `localhost` or IPs (IPs may change).

### Port Management

Manage which ports are exposed and how traffic is routed to your app:

```bash
# View current port mappings for an app
dokku ports:report myapp

# View all port mappings (including scheme)
dokku ports:report myapp --ports-map

# Check what port the app listens on inside the container
dokku config:get myapp DOKKU_PORT
```

#### Adding Port Mappings

Expose additional ports or map host ports to container ports:

```bash
# Map host port 8080 to container port 80
dokku ports:add myapp http:8080:80

# Map multiple ports
dokku ports:add myapp http:80:8080
dokku ports:add myapp https:443:8080

# Map custom TCP port
dokku ports:add myapp tcp:3000:3000
```

#### Removing Port Mappings

```bash
# Remove a specific port mapping
dokku ports:remove myapp http:8080:80

# Clear all custom port mappings (resets to defaults)
dokku ports:clear myapp
```

#### Common Port Scenarios

| Scenario | Command |
|----------|---------|
| App listens on 8080, expose on 80 | `dokku ports:add myapp http:80:8080` |
| Expose admin panel on separate port | `dokku ports:add myapp http:8081:8081` |
| WebSocket support needed | Ensure port mapping includes WebSocket-capable scheme |
| Debugging without proxy | `dokku network:set myapp bind-all-interfaces true` |

#### Port Detection

Dokku automatically detects ports via:
1. **Dockerfile EXPOSE** instruction
2. **`ports` plugin configuration** (via `dokku ports:set`)
3. **PORT** environment variable (set automatically by Dokku for buildpack apps, defaults to 5000)

```bash
# Set port explicitly (overrides detection)
dokku config:set myapp DOKKU_PORT=8080

# Check which port Dokku detected
dokku ports:report myapp | grep detected
```

#### Port Discovery for New Apps

When deploying from a container registry or unfamiliar image, the app may listen on an unexpected port. Dokku's auto-detected port may not match the actual listening port, resulting in 502 errors. Use this workflow to find and fix the correct port:

```bash
# Step 1: Check what Dokku detected vs what's configured
dokku ports:report myapp

# Step 2: Find the actual listening port inside the container
docker exec myapp.web.1 ss -tlnp 2>/dev/null || docker exec myapp.web.1 netstat -tlnp 2>/dev/null

# Step 3: Verify by curling the container internally
# Try the detected port first, then any others found in Step 2
docker exec myapp.web.1 curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/

# Step 4: Fix the port mapping if needed
# If the app listens on 18789 but Dokku mapped to 5000:
dokku ports:set myapp http:80:18789

# Step 5: Restart to apply
dokku ps:restart myapp

# Step 6: Verify externally
curl -s -o /dev/null -w '%{http_code}' http://myapp.your-domain.com/
```

**Common signs of port mismatch:**
- App container is running but URL returns **502 Bad Gateway**
- `dokku logs myapp` shows no errors (app started fine)
- `docker exec myapp.web.1 curl localhost:<port>` works but external URL doesn't

**Tip:** Also check if the app binds to `127.0.0.1` (localhost only) instead of `0.0.0.0` (all interfaces). Apps that bind to localhost won't be reachable by nginx even with correct port mappings. Check the app's docs for a host/bind configuration option.

**Additional debugging:**
```bash
# Check nginx proxy configuration
dokku nginx:show-config myapp

# Check if ports are accessible from outside
nc -zv your-server-ip 80
nc -zv your-server-ip 443
```

---

## Resource Limits

Control CPU and memory allocation per app:

```bash
# Set memory limit for an app
dokku resource:limit myapp --memory 512
dokku resource:limit myapp --memory 1024

# Set CPU limit (number of CPUs)
dokku resource:limit myapp --cpu 1

# Set both memory and CPU
dokku resource:limit myapp --memory 512 --cpu 0.5

# View current limits
dokku resource:report myapp

# View limits for all apps
dokku resource:report

# Clear limits (remove restrictions)
dokku resource:limit-clear myapp
```

**Memory units:** Value is in megabytes by default. Apps exceeding their memory limit will be killed by Docker (OOMKilled).

**CPU units:** Can be fractional (e.g., `0.5` = half a CPU core). Maps to Docker's `--cpus` flag.

```bash
# Set resource reservations (guaranteed minimums)
dokku resource:reserve myapp --memory 256

# Clear reservations
dokku resource:reserve-clear myapp

# View reservations
dokku resource:report myapp
```

**Limits vs Reservations:**
- **Limit** — maximum the app can use. Exceeding memory limit kills the container.
- **Reserve** — guaranteed minimum. Docker won't schedule other containers into reserved resources.

After changing limits, restart or rebuild the app:

```bash
dokku ps:restart myapp
```

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
    },
    {
      "name": "ready",
      "type": "readiness",
      "path": "/ready",
      "attempts": 3
    }
  ]
}
```

### Healthcheck Options

| Field | Values | Description |
|-------|--------|-------------|
| `type` | `startup`, `readiness`, `liveness` | When check runs |
| `path` | `/health`, `/ready`, etc. | HTTP endpoint to check |
| `attempts` | Number (1-10) | Retry attempts before failing |
| `wait` | Seconds (default 0) | Delay before first check |
| `timeout` | Seconds (default 5) | Max time per check |
| `port` | Port number | Port to check (default from app) |

### Healthcheck Behavior

- **Without healthchecks**: 10-second uptime + port listening check
- **With healthchecks**: Custom checks, old container only replaced after new passes

```bash
# Test healthcheck endpoint
curl http://myapp.domain.com/health
curl http://myapp.domain.com/ready
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

# 2. Restore storage
mkdir -p /var/lib/dokku/data/storage/myapp
tar -xzf myapp-storage.tar.gz -C /var/lib/dokku/data/storage/
# Note: If tar contains appname/ directory, move contents:
cd /var/lib/dokku/data/storage/
tar -xzf myapp-storage.tar.gz
cp -r appname/* myapp/

# 3. Mount storage
dokku storage:mount myapp /var/lib/dokku/data/storage/myapp:/app/data

# 4. Set config manually (export format not directly importable)
# Extract values from backup and set:
dokku config:set myapp KEY1=value1 KEY2=value2

# 5. Deploy
git push dokku main
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
dokku storage:ensure-directory my-app

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

## Resources

- [Dokku Documentation](https://dokku.com/docs/)
- [Dokku GitHub](https://github.com/dokku/dokku)
- [Installation Guide](https://dokku.com/docs/getting-started/installation/)
