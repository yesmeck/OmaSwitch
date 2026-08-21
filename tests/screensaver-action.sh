#!/usr/bin/env bash

set -euo pipefail

helper="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/omaswitch"
actual="$(sed -n 's/^    screensaver) \(.*\) ;;/\1/p' "$helper")"

if [[ "$actual" != "omarchy launch screensaver force" ]]; then
  printf 'expected forced screensaver launch, got: %s\n' "$actual" >&2
  exit 1
fi
