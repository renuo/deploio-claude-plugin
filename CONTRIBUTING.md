# Contributing

## Structure

Skills live in `skills/<name>/SKILL.md`. Each skill follows the coordinator pattern — it never runs `nctl` commands directly but spawns `agents/deploio-cli.md` with `mode: bypassPermissions`.

Framework-specific defaults for the deploy skill live in `skills/deploio-deploy/references/<FRAMEWORK>.md` — one file per framework, read on demand.

Cross-skill troubleshooting patterns go in `skills/shared/troubleshooting.md`.

## Editing skills

- Keep `SKILL.md` concise — move heavy reference content into `references/` subdirectories
- Follow the existing coordinator pattern and communication style (plain language to user, never raw nctl commands)
- Use Deploio's terminology: **scheduled jobs** (not "cron jobs"), **worker jobs** (not "workers")
- Test against a real Deploio project before submitting

## Releasing a new version

Bump `"version"` in `.claude-plugin/plugin.json`, commit, and push to `main`. The GitHub Actions workflow creates the git tag and GitHub release automatically.

Version format: `MAJOR.MINOR.PATCH` following [semver](https://semver.org).

## Reporting issues

Open an issue at [github.com/renuo/deploio-claude-plugin/issues](https://github.com/renuo/deploio-claude-plugin/issues).

## Resources

- [Deploio documentation](https://guides.deplo.io/)
- [Nine documentation](https://docs.nine.ch)
- [nctl CLI](https://github.com/ninech/nctl)
- [Claude Code plugin docs](https://code.claude.com/docs)
