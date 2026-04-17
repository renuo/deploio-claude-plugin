#!/bin/bash
# Deploio Claude Code Uninstaller
# Removes all Deploio components installed by install.sh — from either the
# current project (./.claude/) or the global directory (~/.claude/).
# Only removes Deploio-specific files — leaves the rest of .claude/ untouched.
#
# Usage:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/renuo/deploio-claude-plugin/main/uninstall.sh)"
#
# Non-interactive (CI / piped):
#   DEPLOIO_INSTALL_SCOPE=global  ...uninstall.sh   # remove from ~/.claude/
#   DEPLOIO_INSTALL_SCOPE=project ...uninstall.sh   # remove from ./.claude/

set -euo pipefail

# --- helpers ----------------------------------------------------------------

info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()    { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m==>\033[0m %s\n' "$*"; }
fail()  { printf '\033[1;31mError:\033[0m %s\n' "$*" >&2; exit 1; }

# --- resolve install scope --------------------------------------------------

resolve_scope() {
  local scope="${DEPLOIO_INSTALL_SCOPE:-}"

  if [ -z "$scope" ] && { exec 3</dev/tty; } 2>/dev/null; then
    printf '\033[1;34m==>\033[0m Uninstall scope:\n'
    printf '    [g] Global  — ~/.claude/ [default]\n'
    printf '    [p] Project — ./.claude/\n'
    printf 'Choose [G/p]: '
    local answer
    read -r answer <&3 || answer=""
    exec 3<&-
    case "$answer" in
      p|P|project) scope="project" ;;
      *)           scope="global" ;;
    esac
  fi

  case "${scope:-global}" in
    global)  CLAUDE_DIR="$HOME/.claude" ;;
    project) CLAUDE_DIR="$PWD/.claude" ;;
    *)       fail "Invalid DEPLOIO_INSTALL_SCOPE: '$scope' (expected 'global' or 'project')" ;;
  esac

  info "Uninstalling from: $CLAUDE_DIR"
}

resolve_scope

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

remove_file "$CLAUDE_DIR/agents/deploio-cli.md"

# --- skills -----------------------------------------------------------------

remove_dir "$CLAUDE_DIR/skills/deploio-deploy"
remove_dir "$CLAUDE_DIR/skills/deploio-manage"
remove_dir "$CLAUDE_DIR/skills/deploio-debug"
remove_dir "$CLAUDE_DIR/skills/deploio-provision"
remove_dir "$CLAUDE_DIR/skills/deploio-ci-cd"
remove_dir "$CLAUDE_DIR/skills/shared"

# --- hooks ------------------------------------------------------------------

remove_file "$CLAUDE_DIR/hooks/deploio-guard-destructive.sh"

# --- commands ---------------------------------------------------------------

remove_file "$CLAUDE_DIR/commands/deploy.md"
remove_file "$CLAUDE_DIR/commands/debug.md"

# --- clean up empty directories ---------------------------------------------

for dir in "$CLAUDE_DIR/agents" "$CLAUDE_DIR/skills" "$CLAUDE_DIR/hooks" "$CLAUDE_DIR/commands"; do
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
