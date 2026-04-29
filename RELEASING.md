# Releasing

Cutting a release means moving four files in lockstep, then pushing to `main`. The GitHub Actions workflow at `.github/workflows/` watches `.claude-plugin/plugin.json` and tags + releases automatically once it lands on `main` — but only the *plugin* version. Everything else (marketplace listing, changelog, per-skill metadata) is your responsibility.

This document is the checklist. Run through it top-to-bottom every time.

## When to release

- Bug fix, security patch, doc-only change → **PATCH** (`1.2.0` → `1.2.1`)
- New skill, new hook, new command, new feature, additive behavior change → **MINOR** (`1.2.1` → `1.3.0`)
- Removed / renamed skill, breaking change to an executor agent's task spec, hook event surface change that breaks downstream automation → **MAJOR** (`1.x.y` → `2.0.0`)

The agent ↔ skill executor spec (e.g. `task: deploy` fields) is an internal contract — bump MINOR when its shape changes, since the plugin still works end-to-end. Reserve MAJOR for things a *user* would feel.

## Plugin version vs skill version

These are intentionally decoupled:

- **Plugin version** (`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`) tracks the bundle as a whole. Bump on every release.
- **Skill version** (`skills/<name>/SKILL.md` frontmatter `metadata.version`) tracks that skill's behavior. Bump only when *that* skill's contents changed in this release. Skip skills that didn't change.

Most plugin releases bump only one or two skill versions. Bumping all five "to keep them in sync" is wrong — it inflates each skill's history with no real change behind the bump.

## The four files

| File | What to update |
|---|---|
| `.claude-plugin/plugin.json` | `"version"` (one occurrence) |
| `.claude-plugin/marketplace.json` | `"version"` in **two** places: `metadata.version` and `plugins[0].version` — both must match |
| `skills/<name>/SKILL.md` | `metadata.version` for **only the skills changed** in this release |
| `CHANGELOG.md` | New entry at the top (under the header), dated today, with `### Added` / `### Changed` / `### Fixed` sections matching what's in the diff |

## Step-by-step

1. **Decide the version.** Read the diff since the last tag (`git log $(git describe --tags --abbrev=0)..HEAD --oneline`) and pick PATCH / MINOR / MAJOR per the table above. Pick the next number from the current `plugin.json` value, not from `marketplace.json` (the source of truth is `plugin.json` since the autorelease watches it).

2. **Edit the four files** in the order they're listed above. For each, save and check the change is the *only* version-string change in that file (`git diff <file>`).

3. **Run the verification block** (below). It checks the three plugin-level versions agree and that CHANGELOG names the new version. Fix anything it reports before continuing.

4. **Run the project's existing tests / installs** if the changes touched anything user-facing. At minimum:
   - `bash -n install.sh && bash -n uninstall.sh` (syntax check the install scripts)
   - A round-trip flat install into a scratch dir followed by uninstall, to confirm the install scripts still work
   - For hook changes, a manual smoke test of each hook script (`echo '{"tool_input":{...}}' | bash hooks/<name>.sh`)

5. **Commit** with subject `chore(release): <version>` and a body that mirrors the CHANGELOG entry (or just summarizes it).

6. **Push to `main`.** The GitHub Actions workflow tags and creates the GitHub release. Watch the run pass before considering the release shipped.

## Verification block

Run this from the repo root before committing — it surfaces drift between the four files:

```bash
PV=$(jq -r '.version' .claude-plugin/plugin.json)
MM=$(jq -r '.metadata.version' .claude-plugin/marketplace.json)
MP=$(jq -r '.plugins[0].version' .claude-plugin/marketplace.json)
CL=$(grep -m1 -oE '\[[0-9]+\.[0-9]+\.[0-9]+\]' CHANGELOG.md | tr -d '[]')

printf "plugin.json:                %s\n" "$PV"
printf "marketplace.json metadata:  %s\n" "$MM"
printf "marketplace.json plugins:   %s\n" "$MP"
printf "CHANGELOG.md (top entry):   %s\n" "$CL"

if [ "$PV" = "$MM" ] && [ "$PV" = "$MP" ] && [ "$PV" = "$CL" ]; then
  echo "OK — all four agree on $PV"
else
  echo "DRIFT — fix before committing"
  exit 1
fi

echo
echo "Skill versions (only the ones you changed in this release should differ from the previous tag):"
for f in skills/*/SKILL.md; do
  v=$(awk '/^metadata:/{m=1; next} m && /^  version:/{print $2; exit}' "$f")
  printf "  %-32s %s\n" "$(basename "$(dirname "$f")")" "$v"
done
```

The skill section is informational — there's no automatic check that "only the skills you touched are bumped", because that's a judgment call. Compare against the previous tag (`git diff $(git describe --tags --abbrev=0) -- skills/`) if unsure.

## After push

- Check the GitHub Actions run on the merge commit. If it fails, the tag isn't created — fix forward.
- Confirm the new tag exists: `git fetch --tags && git tag -l '<version>'`.
- The marketplace registry picks up the new `marketplace.json` on its next sync. There's no separate publish step.

## If you need to roll back

Don't delete the tag — push a follow-up release with the fix. Tags are immutable contracts; deleting one breaks anyone who already installed at that version.
