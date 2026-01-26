#!/usr/bin/env bash

set -euo pipefail

# Always operate from the repository root
if [[ ! -f "flake.nix" ]]; then
  echo "❌ Run this script from the darwin-config repository root" >&2
  exit 1
fi

repo_path=$(pwd -P)
target_file="darwin-config-path.nix"

previous_path=""
if [[ -f "$target_file" ]]; then
  previous_path=$(<"$target_file" | tr -d '"\n')
fi

printf '"%s"\n' "$repo_path" > "$target_file"

if [[ "$previous_path" == "$repo_path" ]]; then
  echo "ℹ️  DARWIN_CONFIG_PATH already set to $repo_path"
else
  echo "✅ Recorded DARWIN_CONFIG_PATH=$repo_path into $target_file"
fi
