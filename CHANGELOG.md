# Changelog

All notable changes to this project will be documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Versions follow [semver](https://semver.org).

---

## [1.5.0] — 2026-04-29

### Added
- **`auth_stale` blocker** — gather-context distinguishes a stale JWT (expired/corrupt session token) from never-authenticated and emits a verbatim friendly user-facing message telling them to run `nctl auth login`. New `nctl auth errors` section in `shared/troubleshooting.md`.
- **`SubagentStart` nctl version probe** — when the deploio-cli agent is spawned (i.e. just before any nctl call), a hook checks that nctl is installed and meets the plugin's required version (1.16.0). If missing or outdated, the user sees an install/upgrade advisory before any work begins.
- **`RELEASING.md` checklist** — documents the four files that must move together on release (plugin.json, marketplace.json with its two version fields, changed SKILL.md metadata blocks, CHANGELOG.md), with a verification shell block to catch drift before commit.

### Changed
- **Project scoping** — every nctl call from executor and monitor agents now carries `--project=<full-project>`. The agent no longer runs `nctl auth set-project`, which mutated the user's global kubeconfig and silently broke other concurrent shells using the same nctl config. The executor spec drops the legacy `project_suffix` field and the standalone `org` field — `--project=<full-project>` is authoritative.
- **Destructive-command guard now blocks every `nctl auth` subcommand except `whoami`.** The skills prompt the user to run `nctl auth login` / `nctl auth set-org` themselves, with an upfront warning that those commands disrupt any other concurrent session sharing the same nctl config. Both install paths use the same shell-based hard block (the prompt-based variant `hooks/guard-destructive.md` was removed).
- **Hook wiring converged on `hooks/hooks.json` as the single source of truth.** Both hooks (destructive-guard, nctl-probe) declared in one place. Marketplace installs read it directly; flat installs merge the substituted block into `settings.json` via jq, preserving any user-owned hooks. Agent frontmatter no longer carries an inline `hooks:` block.
- **Hook path resolution** uses `${CLAUDE_PLUGIN_ROOT}/hooks/...` in source. Marketplace installs resolve the env var; flat installs substitute the absolute path so global installs no longer lose the guard outside the source repo.
- **`nctl --version`** (works on old and new nctl) replaces `nctl version` (fails on releases below 1.12) in gather-context.

### Fixed
- `install.sh` exit code on local source — the cleanup trap returned 1 under `set -e` when `LOCAL_SRC` was set, breaking CI and scripted installs even on success.
- `install.sh` jq merge is genuinely idempotent and surfaces failures: temp files cleaned up via trap, jq errors abort the install rather than silently leaving the file unchanged with a misleading success message.

---

## [1.1.0] — 2026-03-23

### Added
- `/deploy` slash command — one-word trigger for the deploy skill
- `/debug` slash command — one-word trigger for the debug skill
- Destructive command guard hook — intercepts `nctl delete`, `--replicas=0`, and dangerous exec operations (`db:drop`, `db:reset`) and requires explicit user confirmation before proceeding

---

## [1.0.0] — 2026-03-23

### Added
- **deploio-deploy** skill — first-time deployment with framework auto-detection (Rails, Node.js, Python, PHP, Go, Docker). Framework-specific defaults (env vars, deploy job, health probe, instance size) loaded on demand from per-framework reference files.
- **deploio-manage** skill — day-to-day operations on running apps: env vars, scaling, redeployments, log tailing, Rails console, exec, rollbacks, worker jobs, scheduled jobs, custom domains, health probes.
- **deploio-debug** skill — autonomous diagnosis: pulls app status, release history, build logs, and runtime stats in parallel; cross-references live platform config (`nctl get app -o yaml`) against observed symptoms; proposes and applies fixes.
- **deploio-provision** skill — managed backing services: PostgreSQL (Economy and Business tiers), MySQL, Redis-compatible KVS, OpenSearch, S3-compatible object storage. Extracts credentials and injects env vars automatically.
- **deploio-ci-cd** skill — CI/CD setup for GitHub Actions, GitLab CI, CircleCI, and Bitbucket Pipelines. Includes multi-environment (staging/production) and per-PR preview environment templates.
- **deploio-cli** background agent — executes all `nctl` commands on behalf of coordinator skills with `bypassPermissions`.
- `/deploy` slash command — one-word trigger for the deploy skill
- `/debug` slash command — one-word trigger for the debug skill
- Destructive command guard hook — intercepts `nctl delete`, `--replicas=0`, and dangerous exec operations (`db:drop`, `db:reset`) and requires explicit user confirmation before proceeding
