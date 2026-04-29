# Changelog

All notable changes to this project will be documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Versions follow [semver](https://semver.org).

---

## [1.2.1] — 2026-04-29

### Changed
- **nctl version probe** moved from `SessionStart` to `SubagentStart` with matcher `deploio-cli`. Now fires precisely when the deploio-cli agent is spawned (i.e. when nctl is about to run), instead of on every session start including `/clear` and auto-compactions. The script's stdout is rewritten as a directive for Claude (since SubagentStart output is injected into Claude's context, not displayed in the user's terminal) so the upgrade message is reliably surfaced to the user.
- **Hook wiring converged on a single source of truth.** Both hooks (destructive-guard and nctl-probe) are now declared in `hooks/hooks.json` and nowhere else. Marketplace installs read it directly; flat installs merge the substituted block into `settings.json`. The agent's frontmatter no longer carries an inline `hooks:` block — same scope on both install paths (whole session, not agent-only).
- **Destructive-guard semantics on flat install** unified to the shell-based hard block (matching marketplace behavior). The prompt-based variant (`hooks/guard-destructive.md`) is removed; the guard now hard-blocks via exit 2 across both install paths.

### Fixed
- `install.sh` jq merge is genuinely idempotent and surfaces failures: temp files are cleaned up via trap, `jq` errors abort the install rather than silently leaving the file unchanged with a misleading success message. The merge preserves user-owned hooks (e.g. PreToolUse on Edit, Stop) and only strips entries pointing into the Deploio hooks directory.

---

## [1.2.0] — 2026-04-29

### Added
- **SessionStart `nctl` version probe** — checks at session start that `nctl` is installed and at least at the plugin's required version (1.16.0). Surfaces a one-line install/upgrade advisory if missing or outdated, never blocks the session.
- **`auth_stale` blocker** — gather-context now distinguishes a stale JWT (expired/corrupt session token) from never-authenticated and emits a verbatim friendly message telling the user to run `nctl auth login` themselves. New `nctl auth errors` section in `shared/troubleshooting.md`.

### Changed
- **Project scoping** — every `nctl` call from the executor and monitor agents now carries `--project=<full-project>`. The agent no longer runs `nctl auth set-project`, which mutated the user's global kubeconfig and silently broke other concurrent shells. Executor spec replaces `project_suffix` with explicit `org` + `project` fields.
- **Destructive-guard hook** — now blocks every `nctl auth` subcommand except `whoami`. The skill prompts the user to run `nctl auth login` / `nctl auth set-org` themselves with an upfront warning that those commands disrupt other concurrent sessions sharing the same nctl config.
- **Hook path resolution** — agent frontmatter now uses `${CLAUDE_PLUGIN_ROOT}/hooks/guard-destructive.sh` so the hook resolves correctly regardless of CWD. Marketplace installs use the env var directly; `install.sh` substitutes the absolute path on flat installs so global installs no longer lose the guard outside the source repo.
- **Version flag** — gather-context now uses `nctl --version` (works on old and new nctl) instead of `nctl version` (fails on releases below 1.12).

### Fixed
- `install.sh` exit code on local source — the cleanup trap returned 1 under `set -e` when `LOCAL_SRC` was set, breaking CI and scripted installs even on success.

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
