# Migrating from Railway to Dokku

TODO: This is a stub guide for migrating containers and data from Railway to Dokku.

## Migration Wizard - Pre-Migration Questionnaire

### Railway Account
| Question | Variable | Example |
|----------|----------|---------|
| What is the Railway API token? | `RAILWAY_TOKEN` | ******** |
| What is the project ID? | `RAILWAY_PROJECT_ID` | xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx |
| What is the service ID? | `RAILWAY_SERVICE_ID` | xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx |
| What is the service name? | `SERVICE_NAME` | my-app |

### Application
| Question | Variable | Example |
|----------|----------|---------|
| What is the git repository URL? | `GIT_REPO` | git@github.com:user/repo.git |
| What branch to deploy? | `GIT_BRANCH` | main |
| What environment variables are needed? | `ENV_VARS` | KEY1=value1 KEY2=value2 |
| What is the internal container port? | `INTERNAL_PORT` | 8080 |
| What domain should be used? | `DOMAIN` | app.example.com |
| What email for Let's Encrypt? | `SSL_EMAIL` | admin@example.com |

### Data Migration
| Question | Variable | Example |
|----------|----------|---------|
| Are there Railway volumes attached? | `HAS_VOLUMES` | yes/no |
| What is the volume name? | `VOLUME_NAME` | data |
| What is the volume mount path? | `VOLUME_MOUNT` | /data |

## TODO Items

- [ ] Document Railway CLI installation and authentication
- [ ] Document how to export environment variables from Railway
- [ ] Document how to export data from Railway volumes
- [ ] Document Railway-specific quirks (e.g., ephemeral filesystem)
- [ ] Add data transfer methods (Railway CLI, direct download)
- [ ] Add verification steps
- [ ] Add troubleshooting section

## Prerequisites

- Railway CLI installed
- Railway API token
- Access to Railway project
- Sufficient disk space on Dokku server

## Migration Steps

TODO: Implement migration steps based on testing.

1. Deploy app on Dokku
2. Export data from Railway
3. Transfer data to Dokku
4. Configure environment variables
5. Verify and test

## Resources

- Railway Documentation: https://docs.railway.app/
- Railway CLI: https://github.com/railwayapp/cli
