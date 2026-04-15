# Migrating from Upsun / Platform.sh to Dokku

TODO: This is a stub guide for migrating containers and data from Upsun (formerly Platform.sh) to Dokku.

## Migration Wizard - Pre-Migration Questionnaire

### Upsun Account
| Question | Variable | Example |
|----------|----------|---------|
| What is the Upsun project ID? | `UPSUN_PROJECT_ID` | xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx |
| What is the environment name? | `UPSUN_ENVIRONMENT` | main |
| What is the API token? | `UPSUN_TOKEN` | ******** |
| What region is the project in? | `UPSUN_REGION` | us-3.platform.sh |

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
| Are there services (MySQL, PostgreSQL, Redis)? | `HAS_SERVICES` | yes/no |
| What services are used? | `SERVICE_TYPES` | postgresql, redis |
| What are the service endpoints? | `SERVICE_ENDPOINTS` | database, cache |
| Are there file mounts? | `HAS_MOUNTS` | yes/no |
| What is the mount path? | `MOUNT_PATH` | /uploads |

## TODO Items

- [ ] Document Upsun CLI installation and authentication
- [ ] Document how to export environment variables from Upsun
- [ ] Document how to dump data from Upsun services (MySQL, PostgreSQL, Redis, etc.)
- [ ] Document how to export mounted files
- [ ] Document Upsun-specific quirks (e.g., read-only filesystem except mounts)
- [ ] Add data transfer methods
- [ ] Add verification steps
- [ ] Add troubleshooting section
- [ ] Document .platform.yaml configuration translation to Dokku

## Prerequisites

- Upsun CLI installed
- Upsun API token
- Access to Upsun project
- Sufficient disk space on Dokku server

## Migration Steps

TODO: Implement migration steps based on testing.

1. Analyze Upsun configuration (.platform.yaml, services.yaml)
2. Deploy app on Dokku
3. Create equivalent services on Dokku (or external services)
4. Export data from Upsun services
5. Export mounted files
6. Transfer data to Dokku
7. Configure environment variables
8. Import data to services
9. Verify and test

## Resources

- Upsun Documentation: https://docs.upsun.com/
- Platform.sh CLI: https://docs.platform.sh/administration/cli.html
