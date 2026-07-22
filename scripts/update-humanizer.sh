#!/bin/sh

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(git -C "$script_dir/.." rev-parse --show-toplevel 2>/dev/null) || {
  echo "error: update-humanizer.sh must be run inside the Creator Skills Git repository" >&2
  exit 1
}
cd "$repo_root"

submodule_name=skills/humanizer
submodule_path=$(git config -f .gitmodules --get "submodule.$submodule_name.path" 2>/dev/null) || {
  echo "error: .gitmodules does not declare $submodule_name" >&2
  exit 1
}
branch=$(git config -f .gitmodules --get "submodule.$submodule_name.branch" 2>/dev/null || true)
if [ -z "$branch" ]; then
  branch=main
fi

submodule_root=$(git -C "$submodule_path" rev-parse --show-toplevel 2>/dev/null || true)
if [ "$submodule_root" != "$repo_root/$submodule_path" ]; then
  git submodule update --init -- "$submodule_path"
fi
if [ "$(git -C "$submodule_path" rev-parse --is-shallow-repository)" = "true" ]; then
  git -C "$submodule_path" fetch --unshallow origin
fi

if [ -n "$(git -C "$submodule_path" status --porcelain)" ]; then
  echo "error: $submodule_path has local changes; commit or discard them before updating" >&2
  exit 1
fi

old_revision=$(git -C "$submodule_path" rev-parse HEAD)
git -C "$submodule_path" fetch --prune origin "$branch"
git -C "$submodule_path" show "origin/$branch:SKILL.md" >/dev/null
git -C "$submodule_path" checkout --detach "origin/$branch"

source_skill=$submodule_path/SKILL.md
test -f "$source_skill" || {
  echo "error: upstream Humanizer does not contain SKILL.md" >&2
  exit 1
}

new_revision=$(git -C "$submodule_path" rev-parse HEAD)
version=$(sed -n 's/^version:[[:space:]]*//p' "$source_skill" | head -n 1)
printf 'Humanizer %s advanced from %s to %s\n' "$version" "$old_revision" "$new_revision"
git diff --submodule=log -- "$submodule_path"
make humanizer-check
printf '%s\n' 'Review the upstream diff and bump both native manifest versions before release.'
