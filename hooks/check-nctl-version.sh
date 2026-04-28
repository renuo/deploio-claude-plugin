#!/bin/bash
# Deploio nctl version probe — runs on SessionStart.
# Verifies nctl is installed and meets the plugin's minimum required version.
# Prints an advisory if it isn't; always exits 0 so it never blocks a session.
#
# The minimum version is the lowest nctl release the Deploio skills are
# tested against. Bump it here when the skills start to depend on a newer
# nctl feature. Plugin version lives in .claude-plugin/plugin.json.
MIN_VERSION="1.16.0"

# Returns 0 (true) if $1 is strictly older than $2 (semver order via sort -V).
version_lt() {
  [ "$1" != "$2" ] && \
    [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" = "$1" ]
}

if ! command -v nctl >/dev/null 2>&1; then
  cat <<EOF
[deploio] nctl is not installed — the Deploio skills won't be able to deploy
or manage apps until you install it.

  Install: https://github.com/ninech/nctl
  macOS:   brew install ninech/tap/nctl
EOF
  exit 0
fi

INSTALLED=$(nctl --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
if [ -z "$INSTALLED" ]; then
  echo "[deploio] Could not parse nctl version. Output: $(nctl --version 2>&1 | head -n1)"
  exit 0
fi

if version_lt "$INSTALLED" "$MIN_VERSION"; then
  cat <<EOF
[deploio] nctl $INSTALLED is below the recommended $MIN_VERSION — Deploio
skills may misbehave on older releases.

  Upgrade: https://github.com/ninech/nctl
  macOS:   brew upgrade ninech/tap/nctl
EOF
fi

exit 0
