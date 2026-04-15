# Deploio — Claude Code Plugin

[![Version](https://img.shields.io/github/v/release/renuo/deploio-claude-plugin?label=version)](https://github.com/renuo/deploio-claude-plugin/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)

A [Claude Code](https://claude.ai/code) plugin for deploying and managing apps on [Deploio](https://deploio.com) — Nine Internet Solutions' PaaS platform. Instead of memorising `nctl` commands, just describe what you want in plain language.

```
"Deploy my Rails app to Deploio"
"My app is throwing 503s — what's wrong?"
"Add a PostgreSQL database and wire it up"
"Set up GitHub Actions to deploy on every push"
```

---

## Prerequisites

1. **Install `nctl`** — the Deploio CLI ([full install guide](https://github.com/ninech/nctl#installation)):
   ```bash
   brew install ninech/tap/nctl        # macOS
   # Linux: download from https://github.com/ninech/nctl/releases/latest
   ```

2. **Authenticate**:
   ```bash
   nctl auth login                     # opens browser OAuth
   ```

3. **Verify**:
   ```bash
   nctl auth whoami
   ```

### Agent Sandboxing

`nctl` is a wrapper around the _Kubernetes_ API, so if you're isolating your agents
with [safehouse](https://github.com/eugene1g/agent-safehouse) or [nono](https://github.com/always-further/nono),
you might need to configure extra permissions like [`--enable=kubectl`](https://github.com/eugene1g/agent-safehouse/blob/34a6f80b0de6a9edc0e9029cbf4de726795f40a0/profiles/55-integrations-optional/kubectl.sb).

---

## Installation

Run this from your project directory:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/renuo/deploio-claude-plugin/main/install.sh)"
```

The installer asks whether to install **globally** or only for the **current project**.

Done — Claude will now recognise deployment requests automatically.

You can now run Claude and tell: "Deploy my app to Deploio"

### What gets installed

```
.claude/
├── agents/deploio-cli.md                  # CLI executor agent
├── skills/deploio-{deploy,manage,…}/      # Five skills
├── hooks/deploio-guard-destructive.sh     # Blocks nctl delete and other destructive ops
└── commands/{deploy,debug}.md             # /deploy and /debug shortcuts
```

### Updating

Re-run the install command — it overwrites with the latest version.

### Uninstalling

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/renuo/deploio-claude-plugin/main/uninstall.sh)"
```

---

## Skills

Claude picks the right skill automatically based on what you ask. You don't need to invoke them explicitly.

| Skill | Triggers when you say... |
|---|---|
| **deploio-deploy** | "deploy my app", "host on Deploio", "first deploy", "set up a new Deploio app" |
| **deploio-manage** | "scale to 3 replicas", "add env var", "tail logs", "open rails console", "rollback", "add worker" |
| **deploio-debug** | "app is crashing", "getting 500 errors", "deploy failing", "build error", "OOM", "why is my app broken" |
| **deploio-provision** | "add postgres", "need Redis", "provision a database", "set up object storage", "add Sidekiq" |
| **deploio-ci-cd** | "auto-deploy on push", "GitHub Actions for Deploio", "CI/CD pipeline", "preview environments" |

### What each skill does

**deploio-deploy** — First-time deployment from a git repository to a live HTTPS URL. Detects your framework (Rails, Node.js, Python, PHP, Go, Docker), sets the right defaults (env vars, deploy job, health probe, instance size), confirms the plan with you, then deploys.

**deploio-manage** — Day-to-day operations on a running app: env var changes, scaling, redeployments, log tailing, Rails console, exec, rollbacks, worker jobs, scheduled jobs, custom domains, health probes.

**deploio-debug** — Autonomous diagnosis: pulls app status, release history, build logs, and runtime stats in parallel, identifies the root cause, and proposes a fix. Covers build failures, boot crashes, runtime errors, OOM kills, and worker issues.

**deploio-provision** — Provisions managed backing services and wires them to your app: PostgreSQL (Economy and Business tiers), MySQL, Redis-compatible KVS, OpenSearch, and S3-compatible object storage. Extracts credentials and injects env vars automatically.

**deploio-ci-cd** — Creates a service account, writes the CI workflow file, and guides you through adding secrets. Supports GitHub Actions, GitLab CI, CircleCI, and Bitbucket Pipelines. Includes multi-environment (staging/production) and per-PR preview environment templates.

---

## Supported frameworks

| Framework | Auto-detected via | Defaults set automatically |
|---|---|---|
| Rails | `Gemfile` containing `rails` | `RAILS_ENV`, `SECRET_KEY_BASE`, `rake db:prepare` deploy job, `mini` instance size |
| Node.js | `package.json` | `NODE_ENV=production` |
| Django | `manage.py` + `requirements.txt` | `DJANGO_SECRET_KEY`, `ALLOWED_HOSTS=*` |
| Flask / FastAPI | `app.py` / `main.py` + `requirements.txt` | `SECRET_KEY` |
| PHP / Laravel | `composer.json` | `APP_ENV=production`, `APP_KEY` |
| Go | `go.mod` | listens on `$PORT` |
| Docker | `Dockerfile` | reads port from `EXPOSE` |

---

## How it works

The plugin follows a **coordinator pattern** — Claude never runs `nctl` commands directly in your shell. Instead it spawns background agents with `mode: bypassPermissions` that execute the CLI on your behalf. This means:

- Claude describes what it will do before doing it
- You confirm before anything is created or changed
- Destructive operations always require explicit confirmation
- You can interrupt at any point

---

## Requirements

- Claude Code CLI
- `nctl` v1.14.0 or newer
- A Deploio account ([deploio.com](https://deploio.com))
- Your app in a git repository (GitHub, GitLab, Bitbucket, or self-hosted)

---

## Links

- [Deploio documentation](https://guides.deplo.io/)
- [Nine documentation](https://docs.nine.ch)
- [nctl CLI — installation & reference](https://github.com/ninech/nctl)
- [nctl releases](https://github.com/ninech/nctl/releases/latest)
- [Deploio platform](https://deploio.com)

## Development

Clone the repo and run the installer from your app's project root:

```bash
git clone git@github.com:renuo/deploio-claude-plugin.git
./deploio-claude-plugin/install.sh ./deploio-claude-plugin
```

This skips the GitHub download and copies files directly from the local clone. Re-run after each change to update. Uninstall with `./deploio-claude-plugin/uninstall.sh`.

## Contributing

Skills live in [`skills/`](./skills/), agents in [`agents/`](./agents/). See [`CLAUDE.md`](./CLAUDE.md) for the repository architecture.
