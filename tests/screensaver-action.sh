#!/usr/bin/env bash

set -euo pipefail

helper="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/omaswitch"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

export XDG_CONFIG_HOME="$tmp/config"
export OMARCHY_ARGS="$tmp/omarchy-args"
mkdir -p "$tmp/bin"

cat >"$tmp/bin/omarchy" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"$OMARCHY_ARGS"
EOF
chmod +x "$tmp/bin/omarchy"

PATH="$tmp/bin:$PATH" "$helper" action screensaver
actual="$(paste -sd ' ' "$OMARCHY_ARGS")"
[[ "$actual" == "launch screensaver force" ]]
