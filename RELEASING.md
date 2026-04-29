# Releasing

Cutting a release means moving four files in lockstep, then pushing to `main`. The GitHub Actions workflow at `.github/workflows/` watches `.claude-plugin/plugin.json` and tags + releases automatically once it lands on `main` — but only the *plugin* version. Everything else (marketplace listing, changelog, per-skill metadata) is your responsibility.

This document is the checklist. Run through it top-to-bottom every time.

## When to release

- Bug fix, security patch, doc-only change → **PATCH** (`1.2.0` → `1.2.1`)
- New skill, new hook, new command, new feature, additive behavior change → **MINOR** (`1.2.1` → `1.3.0`)
- Removed / renamed skill, breaking change to an executor agent's task spec, hook event surface change that breaks downstream automation → **MAJOR** (`1.x.y` → `2.0.0`)

The agent ↔ skill executor spec (e.g. `task: deploy` fields) is an internal contract — bump MINOR when its shape changes, since the plugin still works end-to-end. Reserve MAJOR for things a *user* would feel.

## All versions move together

The plugin, marketplace metadata, marketplace plugin entry, and every skill share the **same version number**. On every release, bump all of them — even skills whose contents didn't change in this cycle.

This is a deliberate policy. Per-skill versions used to be decoupled from the plugin (each bumped only when that skill's contents changed), but the seven version numbers across the repo could end up several minor releases apart, making it impossible to tell at a glance which release a user was on without reading every metadata block. Aligned versioning trades skill-level history fidelity for one obvious answer to "which release is this".

If the plugin is ever split into separately-installable units, decoupling will need to come back. Until then: one number, everywhere.

## The four files

| File | What to update |
|---|---|
| `.claude-plugin/plugin.json` | `"version"` (one occurrence) |
| `.claude-plugin/marketplace.json` | `"version"` in **two** places: `metadata.version` and `plugins[0].version` — both must match |
| `skills/<name>/SKILL.md` | `metadata.version` in **every skill** — all five move together with the plugin |
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

OK=true
[ "$PV" = "$MM" ] && [ "$PV" = "$MP" ] && [ "$PV" = "$CL" ] || OK=false

echo
echo "Skill versions:"
for f in skills/*/SKILL.md; do
  v=$(awk '/^metadata:/{m=1; next} m && /^  version:/{print $2; exit}' "$f")
  marker=""; [ "$v" = "$PV" ] || { marker="  (mismatch)"; OK=false; }
  printf "  %-32s %s%s\n" "$(basename "$(dirname "$f")")" "$v" "$marker"
done

echo
if $OK; then
  echo "OK — all versions agree on $PV"
else
  echo "DRIFT — fix before committing"
  exit 1
fi
```

## After push

- Check the GitHub Actions run on the merge commit. If it fails, the tag isn't created — fix forward.
- Confirm the new tag exists: `git fetch --tags && git tag -l '<version>'`.
- The marketplace registry picks up the new `marketplace.json` on its next sync. There's no separate publish step.

## If you need to roll back

Don't delete the tag — push a follow-up release with the fix. Tags are immutable contracts; deleting one breaks anyone who already installed at that version.
