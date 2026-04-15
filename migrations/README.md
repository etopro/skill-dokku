# Hosting Provider Migration Guides

This directory contains step-by-step guides for migrating containers and data from various hosting providers to Dokku.

## Available Migrations

| Provider | Guide | Status |
|----------|-------|--------|
| [Sliplane](./sliplane.md) | Full guide with SSH tunnel workarounds, data transfer, verification | ✅ Complete |
| [Railway](./railway.md) | TODO | 🚧 Stub |
| [Upsun / Platform.sh](./upsun.md) | TODO | 🚧 Stub |

## Using These Guides

Each migration guide follows a similar pattern:
1. **Pre-migration questionnaire** - Gather all required information
2. **Prerequisites** - Server access, disk space checks
3. **Provider-specific access patterns** - SSH, API, CLI quirks
4. **Dokku setup** - App creation, deployment, SSL
5. **Data migration** - Export, transfer, import
6. **Verification** - Checksums, file counts, functionality
7. **Troubleshooting** - Common issues and solutions
8. **Cleanup** - Remove temporary files

## Contributing

To add a new migration guide:
1. Copy an existing guide as a template
2. Update with provider-specific details
3. Document any quirks or workarounds discovered
4. Test the guide end-to-end if possible
