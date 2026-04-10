#!/bin/bash
# Deploio Claude Code Uninstaller
# Removes all Deploio components installed by install.sh.
# Only removes Deploio-specific files — leaves .claude/ and other files untouched.
#
# Usage:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/renuo/deploio-claude-plugin/main/uninstall.sh)"

set -euo pipefail

# --- helpers ----------------------------------------------------------------

info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()    { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m==>\033[0m %s\n' "$*"; }

removed=0

remove_file() {
  if [ -f "$1" ]; then
    rm "$1"
    info "Removed $1"
    removed=$((removed + 1))
  fi
}

remove_dir() {
  if [ -d "$1" ]; then
    rm -rf "$1"
    info "Removed $1"
    removed=$((removed + 1))
  fi
}

# --- agent ------------------------------------------------------------------

remove_file ".claude/agents/deploio-cli.md"

# --- skills -----------------------------------------------------------------

remove_dir ".claude/skills/deploio-deploy"
remove_dir ".claude/skills/deploio-manage"
remove_dir ".claude/skills/deploio-debug"
remove_dir ".claude/skills/deploio-provision"
remove_dir ".claude/skills/deploio-ci-cd"
remove_dir ".claude/skills/shared"

# --- hooks ------------------------------------------------------------------

remove_file ".claude/hooks/deploio-guard-destructive.sh"

# --- commands ---------------------------------------------------------------

remove_file ".claude/commands/deploy.md"
remove_file ".claude/commands/debug.md"

# --- clean up empty directories ---------------------------------------------

for dir in .claude/agents .claude/skills .claude/hooks .claude/commands; do
  if [ -d "$dir" ] && [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
    rmdir "$dir"
    info "Removed empty directory $dir"
  fi
done

# --- summary ----------------------------------------------------------------

echo ""
if [ "$removed" -gt 0 ]; then
  ok "Deploio Claude Code skills uninstalled ($removed items removed)."
else
  warn "Nothing to uninstall — no Deploio components found."
fi
echo ""
