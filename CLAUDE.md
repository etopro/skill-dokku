# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an AI skill for deploying and managing [Dokku](https://dokku.com/) on Linux VMs. The skill is documentation-based with helper bash scripts for common operations.

## Structure

- `SKILL.md` - Main skill documentation with capabilities and usage
- `scripts/` - Helper bash scripts for common Dokku operations
- `CLAUDE.md` - This file, guidance for AI working on this project

## Adding Scripts

When adding new helper scripts to `scripts/`:
1. Make them executable (`chmod +x`)
2. Include error handling (`set -e`, `set -u`)
3. Document usage with comments at the top
4. Follow naming convention: `dokku-<operation>.sh`

## Important Notes

- This is a documentation-first project, not a compiled application
- Scripts are helpers, not the primary interface
- Dokku commands are typically run via SSH on the remote server
- Always test scripts on a non-production Dokku instance first
- Dokku docs: https://dokku.com/docs/
