#!/bin/bash
# Deploio Claude Code Installer
# Installs Deploio skills and agents into the current project's .claude/ directory.
# Project-level agents support permissionMode and hooks, so nctl commands run
# without permission prompts and destructive operations are guarded automatically.
#
# Usage:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/renuo/deploio-claude-plugin/main/install.sh)"
#
# Local testing (skip download, use a local checkout):
#   ./install.sh /path/to/deploio-claude-plugin
#
# Re-run to update to the latest version.
# Run uninstall.sh to remove all Deploio components cleanly.

set -euo pipefail

REPO="renuo/deploio-claude-plugin"
BRANCH="main"
TARBALL_URL="https://github.com/${REPO}/archive/refs/heads/${BRANCH}.tar.gz"
TMPDIR_PREFIX="deploio-install"

# --- helpers ----------------------------------------------------------------

info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()    { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
fail()  { printf '\033[1;31mError:\033[0m %s\n' "$*" >&2; exit 1; }

cleanup() { [ -z "${LOCAL_SRC:-}" ] && [ -d "${tmpdir:-}" ] && rm -rf "$tmpdir"; }
trap cleanup EXIT

# --- resolve source ---------------------------------------------------------

if [ -n "${1:-}" ]; then
  # Local path provided — use it directly, no download
  [ -d "$1" ] || fail "Local path not found: $1"
  src="$1"
  LOCAL_SRC=1
  info "Using local source: $src"
else
  # Download from GitHub
  command -v curl  >/dev/null 2>&1 || fail "curl is required but not found"
  command -v tar   >/dev/null 2>&1 || fail "tar is required but not found"

  info "Downloading Deploio Claude Code skills..."
  tmpdir=$(mktemp -d -t "${TMPDIR_PREFIX}.XXXXXX")
  curl -fsSL "$TARBALL_URL" | tar -xz -C "$tmpdir" --strip-components=1
  src="$tmpdir"
fi

# --- install agents ---------------------------------------------------------

info "Installing agent..."
mkdir -p .claude/agents
cp "$src/agents/deploio-cli.md" .claude/agents/deploio-cli.md

# --- install skills ---------------------------------------------------------

info "Installing skills..."
mkdir -p .claude/skills

for skill_dir in "$src"/skills/*/; do
  skill_name=$(basename "$skill_dir")
  mkdir -p ".claude/skills/${skill_name}"
  cp -R "$skill_dir"/* ".claude/skills/${skill_name}/"
done

# --- install hooks ----------------------------------------------------------

info "Installing hooks..."
mkdir -p .claude/hooks
cp "$src/hooks/guard-destructive.sh" .claude/hooks/deploio-guard-destructive.sh
chmod +x .claude/hooks/deploio-guard-destructive.sh

# --- install commands -------------------------------------------------------

info "Installing commands..."
mkdir -p .claude/commands

for cmd_file in "$src"/commands/*.md; do
  cp "$cmd_file" ".claude/commands/$(basename "$cmd_file")"
done

# --- summary ----------------------------------------------------------------

echo ""
ok "Deploio Claude Code skills installed!"
echo ""
echo "  Agent:    .claude/agents/deploio-cli.md"
echo "  Skills:   .claude/skills/deploio-{deploy,manage,debug,provision,ci-cd}/"
echo "  Hooks:    .claude/hooks/deploio-guard-destructive.sh"
echo "  Commands: .claude/commands/{deploy,debug}.md"
echo ""
echo "  Make sure nctl is installed and authenticated:"
echo "    nctl auth login"
echo ""
echo "  Then just ask Claude: \"Deploy my app to Deploio\""
echo ""
