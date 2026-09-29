#!/bin/bash
# Deploio nctl version probe.
# Wired as a SubagentStart hook with matcher=deploio-cli — fires the moment
# Claude spawns the deploio-cli agent, just before any nctl call. Anything
# this script writes to stdout becomes context for the spawning Claude (not
# direct output to the user's terminal), so the message is phrased as an
# instruction for Claude to relay to the user.
#
# The minimum is the lowest nctl release the Deploio skills are tested
# against. Bump it here when the skills start to depend on a newer nctl
# feature. Plugin version lives in .claude-plugin/plugin.json.
MIN_VERSION="1.16.0"

# Drain stdin — the host writes the tool-input payload here even when we
# don't consume it; leaving it pending can stall the host process.
cat >/dev/null

version_lt() {
  [ "$1" != "$2" ] && \
    [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" = "$1" ]
}

if ! command -v nctl >/dev/null 2>&1; then
  cat <<'EOF'
[deploio nctl probe] nctl is not installed on this machine — the Deploio
skills cannot deploy or manage apps until the user installs it.

Before doing any work, lead with this message to the user verbatim:

  The Deploio CLI (`nctl`) isn't installed yet. Please install it and ask
  me to retry:
    macOS:  brew install ninech/tap/nctl
    Other:  https://github.com/ninech/nctl
EOF
  exit 0
fi

INSTALLED=$(nctl --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
if [ -z "$INSTALLED" ]; then
  exit 0
fi

if version_lt "$INSTALLED" "$MIN_VERSION"; then
  cat <<EOF
[deploio nctl probe] The user's nctl is at $INSTALLED — below the recommended
$MIN_VERSION. The Deploio skills may misbehave on older releases.

Before doing any work, lead with this message to the user verbatim:

  Your nctl is at $INSTALLED — Deploio recommends $MIN_VERSION or newer to
  avoid compatibility issues. To upgrade:
    macOS:  brew upgrade ninech/tap/nctl
    Other:  https://github.com/ninech/nctl
EOF
fi

exit 0
