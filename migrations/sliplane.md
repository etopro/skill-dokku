# Migrating from Sliplane to Dokku

This guide documents the process of migrating a container and data from Sliplane hosting to Dokku, based on real-world migration experience.

## Migration Wizard - Pre-Migration Questionnaire

Before starting the migration, gather the following information from the user, for items and sections not yet known:

### Dokku Server
| Question | Variable | Example |
|----------|----------|---------|
| What is the Dokku server IP? | `DOKKU_IP` | 1.2.3.4 |
| What is the SSH user? | `DOKKU_USER` | root |
| What is the app name? | `APP_NAME` | someapp |

### Sliplane Server
| Question | Variable | Example |
|----------|----------|---------|
| What is the SSH tunnel host? | `SLIPLANE_HOST` | ssh-tunnel-xyz.sliplane.app |
| What is the SSH port? | `SLIPLANE_PORT` | 10225 |
| What is the SSH password? | `SLIPLANE_PASS` | ******** |
| What is the SSH user? | `SLIPLANE_USER` | root |
| Where is the data located? | `SLIPLANE_DATA_PATH` | /data/someapp |

### Application
| Question | Variable | Example |
|----------|----------|---------|
| What is the git repository URL? | `GIT_REPO` | git@github.com:user/repo.git |
| What branch to deploy? | `GIT_BRANCH` | main |
| What environment variables are needed? | `ENV_VARS` | KEY1=value1 KEY2=value2 |
| What is the internal container port? | `INTERNAL_PORT` | 8080 |
| What domain should be used? | `DOMAIN` | app.example.com |
| What email for Let's Encrypt? | `SSL_EMAIL` | admin@example.com |
| Where should data be mounted in container? | `CONTAINER_MOUNT_PATH` | /home |

### Verification
After gathering answers, confirm with user:
- [ ] Dokku server accessible
- [ ] Sliplane server accessible
- [ ] Sufficient disk space on Dokku (run `ssh root@DOKKU_IP "df -h"`)
- [ ] Git repository or Docker image repo is correct
- [ ] All environment variables listed

## Prerequisites

- SSH access to Sliplane server (typically via SSH tunnel)
- SSH access to Dokku server
- Sufficient disk space on Dokku server (check with `df -h`)

## Sliplane SSH Access

Sliplane typically uses an SSH tunnel for access. Connection details vary by instance.

**Example:**
```bash
ssh -p 10225 root@ssh-tunnel-ombx.sliplane.app
```

**Important Notes:**
- The SSH connection may print an interactive banner before each session
- Standard tools like `scp`, `rsync`, `sftp` may fail due to this banner
- The `-T`, `-O`, `-q` flags do NOT suppress the banner
- Use `sshpass` for automated authentication

## Migration Steps

### 1. Deploy App on Dokku

```bash
# Create app
ssh root@DOKKU_IP "dokku apps:create APP_NAME"

# Set up git deployment
ssh root@DOKKU_IP "dokku git:sync APP_NAME GIT_REPO BRANCH"

# Set environment variables
ssh root@DOKKU_IP "dokku config:set APP_NAME KEY1=value1 KEY2=value2"

# Configure port mapping (IMPORTANT: external port must be 80 for SSL)
ssh root@DOKKU_IP "dokku ports:set APP_NAME http:80:INTERNAL_PORT"

# Add custom domain
ssh root@DOKKU_IP "dokku domains:add APP_NAME your-domain.com"

# Set up SSL with Let's Encrypt
ssh root@DOKKU_IP "dokku letsencrypt:enable APP_NAME EMAIL"
```

### 2. Configure Storage Mount

```bash
# Create storage directory
ssh root@DOKKU_IP "mkdir -p /var/lib/dokku/data/storage/APP_NAME"

# Mount storage to container path
ssh root@DOKKU_IP "dokku storage:mount APP_NAME /var/lib/dokku/data/storage/APP_NAME:/CONTAINER_PATH"
```

### 3. Prepare Data for Transfer

**Connect to Sliplane and identify data location:**
```bash
sshpass -p 'PASSWORD' ssh -p PORT root@TUNNEL_HOST "ls -la /data/"
```

**Create compressed archive of data:**
```bash
sshpass -p 'PASSWORD' ssh -p PORT root@TUNNEL_HOST "tar -czf /data/backup.tar.gz -C /data/directory ."
```

**Verify archive integrity:**
```bash
sshpass -p 'PASSWORD' ssh -p PORT root@TUNNEL_HOST "tar -tzf /data/backup.tar.gz | wc -l"
```

### 4. Transfer Data to Dokku

**Method 1: SCP via Dokku server (requires sshpass installed)**

First install sshpass on Dokku server:
```bash
ssh root@DOKKU_IP "apt-get update && apt-get install -y sshpass"
```

Then transfer:
```bash
ssh root@DOKKU_IP "sshpass -p 'SLIPLANE_PASS' scp -P SLIPLANE_PORT -o StrictHostKeyChecking=no root@SLIPLANE_HOST:/data/backup.tar.gz /mnt/volume/backup.tar.gz"
```

**Method 2: Via local machine (slower, uses local as intermediary)**
```bash
# Copy from Sliplane to local
sshpass -p 'PASSWORD' scp -P PORT root@TUNNEL_HOST:/data/backup.tar.gz /tmp/backup.tar.gz

# Copy from local to Dokku
scp /tmp/backup.tar.gz root@DOKKU_IP:/mnt/volume/backup.tar.gz
```

### 5. Verify Transfer

**Check file sizes match:**
```bash
# Source
sshpass -p 'PASSWORD' ssh -p PORT root@TUNNEL_HOST "ls -lh /data/backup.tar.gz"

# Destination
ssh root@DOKKU_IP "ls -lh /mnt/volume/backup.tar.gz"
```

**Verify MD5 checksums:**
```bash
# Source
sshpass -p 'PASSWORD' ssh -p PORT root@TUNNEL_HOST "md5sum /data/backup.tar.gz"

# Destination
ssh root@DOKKU_IP "md5sum /mnt/volume/backup.tar.gz"
```

### 6. Extract Data

```bash
# Extract to storage mount
ssh root@DOKKU_IP "cd /var/lib/dokku/data/storage/APP_NAME && tar -xzf /mnt/volume/backup.tar.gz"

# Verify extraction
ssh root@DOKKU_IP "du -sh /var/lib/dokku/data/storage/APP_NAME"
```

### 7. Restart App

```bash
ssh root@DOKKU_IP "dokku ps:restart APP_NAME"
```

## Troubleshooting

### SSH Banner Blocking Automation

**Problem:** Sliplane SSH prints interactive banner, breaking scp/rsync/sftp automation.

**Solutions:**
1. Use sshpass for authentication
2. Run transfer commands FROM Dokku server (after installing sshpass)
3. Cat pipe method (harder to monitor progress):
   ```bash
   sshpass -p 'PASS' ssh -p PORT root@HOST "cat /data/backup.tar.gz" | \
   ssh root@DOKKU_IP "cat > /mnt/volume/backup.tar.gz"
   ```

### Disk Space Issues

**Check available space:**
```bash
ssh root@DOKKU_IP "df -h"
```

**Clean up if needed:**
```bash
# Remove partial transfers
ssh root@DOKKU_IP "rm -f /mnt/volume/partial-file.tar.gz"

# Docker cleanup
ssh root@DOKKU_IP "docker system prune -f"
```

### SSL Let's Encrypt Failing

**Problem:** ACME challenge returns 404.

**Solution:** External port MUST be 80 for Let's Encrypt HTTP-01 challenge:
```bash
ssh root@DOKKU_IP "dokku ports:set APP_NAME http:80:INTERNAL_PORT"
```

### Tar Extraction Corruption

**Problem:** "file changed as we read it" errors, incomplete extraction.

**Solutions:**
1. Create tar.gz on source FIRST, then copy
2. Verify archive with `tar -tzf` before transfer
3. Remove corrupted partial data and re-extract

### Data Size Changes During Migration

Active databases/caches may change size during migration process.

**Approach:**
1. Stop services on source if possible
2. Archive data quickly
3. Verify file counts match after extraction:
   ```bash
   # Source
   find /data/directory -type f | wc -l

   # Destination
   find /var/lib/dokku/data/storage/APP_NAME -type f | wc -l
   ```

## Cleanup

After successful migration:

```bash
# On Sliplane (if keeping server for now)
sshpass -p 'PASSWORD' ssh -p PORT root@TUNNEL_HOST "rm /data/backup.tar.gz"

# On Dokku
ssh root@DOKKU_IP "rm /mnt/volume/backup.tar.gz"
```

## Checklist

- [ ] App deployed on Dokku
- [ ] Environment variables configured
- [ ] Port mapping set (external:80 for SSL)
- [ ] Domain configured
- [ ] SSL enabled with Let's Encrypt
- [ ] Storage mount configured
- [ ] Data archived on source
- [ ] Archive verified (file count, size)
- [ ] Data transferred to Dokku
- [ ] MD5 checksums verified
- [ ] Data extracted to mount point
- [ ] File counts verified (source vs dest)
- [ ] App restarted
- [ ] App functionality tested
- [ ] Cleanup completed
