# Dokku Management Skill

An AI skill for deploying and managing [Dokku](https://dokku.com/) on Linux VMs.

## Overview

Dokku is a mini-Heroku powered by Docker. This skill helps automate the deployment and management of Dokku instances through SSH commands.

## Capabilities

### Installation & Setup
- Bootstrap Dokku on a fresh Ubuntu/Debian VM
- Configure initial admin user and SSH keys
- Set up global domains and routing

### App Management
- Create, destroy, and list apps
- Configure environment variables
- Scale processes (web, worker, etc.)
- View logs and app status

### Service Management
- Create and manage services (PostgreSQL, Redis, MySQL, MongoDB)
- Link services to apps
- Backup and restore service data

### Deployments
- Deploy apps via git push
- Configure buildpacks or Dockerfile builds
- Handle zero-downtime deployments

### SSL & Domains
- Install and configure Let's Encrypt certificates
- Manage custom domains and routing
- Handle SSL auto-renewal

## Usage

The skill executes Dokku commands via SSH on a remote server. Example commands:

```bash
# List all apps
dokku apps:list

# Create a new app
dokku apps:create myapp

# Set environment variables
dokku config:set myapp NODE_ENV=production

# Link a PostgreSQL service
dokku postgres:link database myapp

# View logs
dokku logs myapp -t
```

## Requirements

- Target system: Ubuntu 20.04+ or Debian 11+
- SSH access with sudo privileges
- At least 1GB RAM (2GB+ recommended)
- Valid DNS records pointing to the server

## Resources

- [Dokku Documentation](https://dokku.com/docs/)
- [Dokku GitHub](https://github.com/dokku/dokku)
