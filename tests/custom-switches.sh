#!/usr/bin/env bash

set -euo pipefail

helper="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/omaswitch"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

export XDG_CONFIG_HOME="$tmp/config"
export XDG_STATE_HOME="$tmp/state"
export TEST_STATE="$tmp/custom-state"
export TEST_ACTION="$tmp/custom-action"
mkdir -p "$XDG_CONFIG_HOME/omaswitch" "$tmp/bin"

cat >"$tmp/bin/custom-status" <<'EOF'
#!/usr/bin/env bash
[[ -f "$TEST_STATE" ]]
EOF

cat >"$tmp/bin/custom-toggle" <<'EOF'
#!/usr/bin/env bash
if [[ -f "$TEST_STATE" ]]; then rm "$TEST_STATE"; else touch "$TEST_STATE"; fi
EOF

cat >"$tmp/bin/custom-action" <<'EOF'
#!/usr/bin/env bash
printf '%s' "$1" >"$TEST_ACTION"
EOF

chmod +x "$tmp/bin/custom-status" "$tmp/bin/custom-toggle" "$tmp/bin/custom-action"

cat >"$XDG_CONFIG_HOME/omaswitch/switches.json" <<EOF
[
  {
    "id": "test-toggle",
    "label": "Test Toggle",
    "icon": "T",
    "statusCommand": ["$tmp/bin/custom-status"],
    "toggleCommand": ["$tmp/bin/custom-toggle"],
    "onLabel": "Enabled",
    "offLabel": "Disabled"
  },
  {
    "id": "test-action",
    "label": "Test Action",
    "actionCommand": ["$tmp/bin/custom-action", "argument with spaces"]
  },
  {
    "id": "wifi",
    "label": "Reserved",
    "statusCommand": ["true"],
    "toggleCommand": ["true"]
  },
  {
    "id": "invalid",
    "label": "Missing command",
    "statusCommand": ["true"]
  }
]
EOF

definitions="$("$helper" switches)"
jq -e '
  length == 2 and
  .[0] == {
    "key": "test-toggle",
    "label": "Test Toggle",
    "icon": "T",
    "on": "Enabled",
    "off": "Disabled",
    "action": false,
    "custom": true
  } and
  .[1].key == "test-action" and
  .[1].action == true
' <<<"$definitions" >/dev/null

jq -e '."test-toggle" == false' <<<"$("$helper" status)" >/dev/null
"$helper" toggle test-toggle
jq -e '."test-toggle" == true' <<<"$("$helper" status)" >/dev/null

"$helper" action test-action
[[ "$(<"$TEST_ACTION")" == "argument with spaces" ]]
