#!/bin/bash

set -euo pipefail

if (($# != 1)) || [[ -z "$1" ]]; then
  printf 'Usage: %s <agent-skill-directory>\n' "$(basename "$0")" >&2
  exit 2
fi

script_dir=$(cd "$(dirname "$0")" && pwd -P)
destination=$1

mkdir -p "$destination"
cp -p \
  "$script_dir/SKILL.md" \
  "$script_dir/agent-notify" \
  "$script_dir/.env.example" \
  "$script_dir/worker.env.example" \
  "$destination/"

for file in SKILL.md agent-notify .env.example worker.env.example; do
  cmp -s "$script_dir/$file" "$destination/$file"
done

printf 'Installed agent-notify skill files to %s\n' "$destination"
