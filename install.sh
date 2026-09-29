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

# Don't end on a falsy short-circuit — under `set -e` + EXIT trap, the trap's
# own non-zero return becomes the script's exit status, even on success.
cleanup() {
  if [ -z "${LOCAL_SRC:-}" ] && [ -d "${tmpdir:-}" ]; then
    rm -rf "$tmpdir"
  fi
}
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
cp "$src/hooks/check-nctl-version.sh" "$CLAUDE_DIR/hooks/deploio-check-nctl-version.sh"
chmod +x "$CLAUDE_DIR/hooks/deploio-check-nctl-version.sh"

# Wire the plugin's hook entries into the user's settings.json. Marketplace
# installs read hooks/hooks.json directly (with ${CLAUDE_PLUGIN_ROOT} resolved
# at hook-exec time). Flat installs have no plugin context, so we substitute
# every ${CLAUDE_PLUGIN_ROOT}/hooks/<name>.sh with the absolute, deploio-
# prefixed install path and merge the result into settings.json. Re-running
# the installer is idempotent: prior entries pointing into $CLAUDE_DIR/hooks/
# are stripped before the new ones are appended.
SETTINGS="$CLAUDE_DIR/settings.json"
HOOK_PREFIX="$CLAUDE_DIR/hooks/"

# Build the substituted hooks block. Two replacements: env-var → absolute
# path, and source script name → installed (prefixed) script name.
NEW_HOOKS_JSON=$(sed \
  -e "s|\${CLAUDE_PLUGIN_ROOT}/hooks/guard-destructive\.sh|${HOOK_PREFIX}deploio-guard-destructive.sh|g" \
  -e "s|\${CLAUDE_PLUGIN_ROOT}/hooks/check-nctl-version\.sh|${HOOK_PREFIX}deploio-check-nctl-version.sh|g" \
  "$src/hooks/hooks.json")

if ! command -v jq >/dev/null 2>&1; then
  info "jq not found — to enable Deploio hooks, copy this block into $SETTINGS:"
  echo "$NEW_HOOKS_JSON"
else
  hooks_tmp=$(mktemp)
  # Make sure the temp file is cleaned up even if jq fails or the script
  # exits unexpectedly. The cleanup trap from the top of the script handles
  # tmpdir; this trap appends to it for hooks_tmp.
  trap 'rm -f "$hooks_tmp"; cleanup' EXIT

  # If settings.json doesn't exist yet, start from an empty object.
  jq_input="$SETTINGS"
  if [ ! -f "$SETTINGS" ]; then
    jq_input=$(mktemp)
    echo '{}' > "$jq_input"
    trap 'rm -f "$hooks_tmp" "$jq_input"; cleanup' EXIT
  fi

  if echo "$NEW_HOOKS_JSON" | jq -s --arg prefix "$HOOK_PREFIX" '
    # Strip any existing entry that already references one of our installed
    # hook scripts (idempotent re-install).
    def strip_deploio:
      map(select(
        (.hooks // []) | any(((.command // .prompt) // "") | startswith($prefix)) | not
      ));

    .[0] as $existing | .[1] as $new |
    ($existing | .hooks //= {}) |
    reduce ($new.hooks | keys[]) as $event (.;
      .hooks[$event] = (((.hooks[$event] // []) | strip_deploio) + $new.hooks[$event])
    )
  ' "$jq_input" - > "$hooks_tmp"; then
    mv "$hooks_tmp" "$SETTINGS"
    ok "Wired Deploio hooks into $SETTINGS"
  else
    fail "jq failed to merge hooks into $SETTINGS — file left unchanged"
  fi

  trap cleanup EXIT
fi

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
echo "  Hooks:    $CLAUDE_DIR/hooks/deploio-guard-destructive.sh
            $CLAUDE_DIR/hooks/deploio-check-nctl-version.sh"
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
