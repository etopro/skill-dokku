# skill-dokku

An AI skill for deploying and managing [Dokku](https://dokku.com/) on Linux VMs via SSH.

Dokku is a mini-Heroku powered by Docker. This skill provides documentation and helper scripts for AI agents to autonomously install, configure, deploy, and manage Dokku apps.

## Structure

- `skills/dokku/SKILL.md` — Main skill documentation (capabilities, commands, workflows)
- `CLAUDE.md` — AI agent guidance for working on this project
- `scripts/` — Helper bash scripts for common operations
- `migrations/` — Hosting provider migration guides (Sliplane, Railway, Upsun)

## Usage

Load `SKILL.md` as context for your AI agent. The skill covers app lifecycle, deployment from git/Docker, SSL, storage, networking, resource management, and more.
