# Changelog

All notable changes to this project will be documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Versions follow [semver](https://semver.org).

---

## [1.0.0] — 2026-03-23

### Added
- **deploio-deploy** skill — first-time deployment with framework auto-detection (Rails, Node.js, Python, PHP, Go, Docker). Framework-specific defaults (env vars, deploy job, health probe, instance size) loaded on demand from per-framework reference files.
- **deploio-manage** skill — day-to-day operations on running apps: env vars, scaling, redeployments, log tailing, Rails console, exec, rollbacks, worker jobs, scheduled jobs, custom domains, health probes.
- **deploio-debug** skill — autonomous diagnosis: pulls app status, release history, build logs, and runtime stats in parallel; cross-references live platform config (`nctl get app -o yaml`) against observed symptoms; proposes and applies fixes.
- **deploio-provision** skill — managed backing services: PostgreSQL (Economy and Business tiers), MySQL, Redis-compatible KVS, OpenSearch, S3-compatible object storage. Extracts credentials and injects env vars automatically.
- **deploio-ci-cd** skill — CI/CD setup for GitHub Actions, GitLab CI, CircleCI, and Bitbucket Pipelines. Includes multi-environment (staging/production) and per-PR preview environment templates.
- **deploio-cli** background agent — executes all `nctl` commands on behalf of coordinator skills with `bypassPermissions`.
- `/deploy` slash command — one-word trigger for the deploy skill.
- `/debug` slash command — one-word trigger for the debug skill.
- Destructive command guard hook — intercepts `nctl delete`, `--replicas=0`, and dangerous exec operations (`db:drop`, `db:reset`) and requires explicit user confirmation before proceeding.
