#!/bin/bash
# Deploio Claude Code Installer
# Installs Deploio skills and agents into a .claude/ directory — either the
# current project (./.claude/) or globally for your user (~/.claude/).
# Project-level agents support permissionMode and hooks, so nctl commands run
# without permission prompts and destructive operations are guarded automatically.
#
# Usage:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/renuo/deploio-claude-plugin/main/install.sh)"
#
# Non-interactive (CI / piped):
#   DEPLOIO_INSTALL_SCOPE=global  ...install.sh   # install to ~/.claude/
#   DEPLOIO_INSTALL_SCOPE=project ...install.sh   # install to ./.claude/
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

# --- resolve install scope --------------------------------------------------

resolve_scope() {
  local scope="${DEPLOIO_INSTALL_SCOPE:-}"

  if [ -z "$scope" ] && { exec 3</dev/tty; } 2>/dev/null; then
    printf '\033[1;34m==>\033[0m Install scope:\n'
    printf '    [g] Global  — ~/.claude/ (available in every project) [default]\n'
    printf '    [p] Project — ./.claude/ (only this directory)\n'
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

  info "Installing to: $CLAUDE_DIR"
}

resolve_scope

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
mkdir -p "$CLAUDE_DIR/agents"
cp "$src/agents/deploio-cli.md" "$CLAUDE_DIR/agents/deploio-cli.md"

# --- install skills ---------------------------------------------------------

info "Installing skills..."
mkdir -p "$CLAUDE_DIR/skills"

for skill_dir in "$src"/skills/*/; do
  skill_name=$(basename "$skill_dir")
  mkdir -p "$CLAUDE_DIR/skills/${skill_name}"
  cp -R "$skill_dir"/* "$CLAUDE_DIR/skills/${skill_name}/"
done

# --- install hooks ----------------------------------------------------------

info "Installing hooks..."
mkdir -p "$CLAUDE_DIR/hooks"
cp "$src/hooks/guard-destructive.sh" "$CLAUDE_DIR/hooks/deploio-guard-destructive.sh"
chmod +x "$CLAUDE_DIR/hooks/deploio-guard-destructive.sh"

# --- install commands -------------------------------------------------------

info "Installing commands..."
mkdir -p "$CLAUDE_DIR/commands"

for cmd_file in "$src"/commands/*.md; do
  cp "$cmd_file" "$CLAUDE_DIR/commands/$(basename "$cmd_file")"
done

# --- summary ----------------------------------------------------------------

echo ""
ok "Deploio Claude Code skills installed!"
echo ""
echo "  Agent:    $CLAUDE_DIR/agents/deploio-cli.md"
echo "  Skills:   $CLAUDE_DIR/skills/deploio-{deploy,manage,debug,provision,ci-cd}/"
echo "  Hooks:    $CLAUDE_DIR/hooks/deploio-guard-destructive.sh"
echo "  Commands: $CLAUDE_DIR/commands/{deploy,debug}.md"
echo ""
echo "  Make sure nctl is installed and authenticated:"
echo "    nctl auth login"
echo ""
echo "  Then:"
echo "    cd <your project>"
echo "    claude"
echo ""
echo "  And ask: \"Deploy my app to Deploio\""
echo ""
