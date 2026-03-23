# CLAUDE.md

This file provides guidance to Claude Code when working in this repository.

## What this repo is

A Claude Code plugin providing five skills for deploying and managing apps on [Deploio](https://deploio.com) — Nine Internet Solutions' PaaS platform. The Deploio CLI is [`nctl`](https://github.com/ninech/nctl).

## Repository structure

```
skills/
  deploio-deploy/       # First-time deployment
    SKILL.md
    references/
      RAILS.md          # Framework-specific defaults (read on demand)
      NODE.md
      PYTHON.md
      PHP.md
      GO.md
      DOCKER.md
  deploio-manage/       # Day-to-day operations on running apps
  deploio-debug/        # Diagnosis and fixing broken apps
  deploio-provision/    # Backing services (PostgreSQL, Redis, S3, etc.)
  deploio-ci-cd/        # CI/CD pipeline setup
  shared/
    troubleshooting.md  # Cross-skill problem/fix reference

agents/
  deploio-cli.md        # Background agent that executes nctl commands

.claude-plugin/
  plugin.json           # Plugin manifest
  marketplace.json      # Marketplace entry (install via /plugin marketplace add)
```

## Key nctl command groups

- `nctl create app` — deploy an app from a git URL
- `nctl update app` — update app config (env vars, build-env, size, workers, jobs)
- `nctl get app` — inspect app state, stats, DNS, credentials
- `nctl exec app` — run commands inside a running container
- `nctl logs app` / `nctl logs build` — stream app or build logs
- `nctl auth` — manage authentication and project context

Official nctl docs: [github.com/ninech/nctl](https://github.com/ninech/nctl)
Deploio docs: [guides.deplo.io](https://guides.deplo.io/)
Nine docs: [docs.nine.ch](https://docs.nine.ch)
## Skill architecture

- **Coordinator pattern** — skills never run `nctl` commands directly; they spawn `deploio-cli` agents with `mode: bypassPermissions` for all execution
- **Progressive disclosure** — `SKILL.md` stays concise; heavy content lives in `references/` subdirectories
- **Framework files are read on demand** — the coordinator reads only `references/<FRAMEWORK>.md` for the detected framework, not all of them

## Versioning

Bump `"version"` in `.claude-plugin/plugin.json` and push to `main` — the GitHub Actions workflow tags and releases automatically.
