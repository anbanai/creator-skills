#!/bin/sh

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(git -C "$script_dir/.." rev-parse --show-toplevel 2>/dev/null) || {
  echo "error: check-humanizer.sh must be run inside the Creator Skills Git repository" >&2
  exit 1
}
cd "$repo_root"

submodule_path=skills/humanizer
url=$(git config -f .gitmodules --get "submodule.$submodule_path.url" 2>/dev/null || true)
branch=$(git config -f .gitmodules --get "submodule.$submodule_path.branch" 2>/dev/null || true)
if [ "$url" != "https://github.com/blader/humanizer.git" ] || [ "$branch" != "main" ]; then
  echo "error: $submodule_path must track the official blader/humanizer main branch" >&2
  exit 1
fi

entry=$(git ls-files --stage -- "$submodule_path")
set -- $entry
if [ "${1:-}" != "160000" ] || [ "${4:-}" != "$submodule_path" ]; then
  echo "error: $submodule_path must be recorded as a Git submodule" >&2
  exit 1
fi

submodule_root=$(git -C "$submodule_path" rev-parse --show-toplevel 2>/dev/null || true)
if [ "$submodule_root" != "$repo_root/$submodule_path" ]; then
  echo "error: initialize $submodule_path before validation" >&2
  exit 1
fi
if [ "$(git -C "$submodule_path" rev-parse --is-shallow-repository)" != "false" ]; then
  echo "error: $submodule_path must have complete history for submodule diff review" >&2
  exit 1
fi
if [ "$(git -C "$submodule_path" remote get-url origin)" != "$url" ]; then
  echo "error: $submodule_path origin does not match $url" >&2
  exit 1
fi

skill=$submodule_path/SKILL.md
test -f "$skill" || {
  echo "error: upstream Humanizer does not contain SKILL.md" >&2
  exit 1
}
grep -q '^name:[[:space:]]*humanizer$' "$skill"
grep -q '^license:[[:space:]]*MIT$' "$skill"

for manifest in .claude-plugin/marketplace.json .claude-plugin/plugin.json .codex-plugin/plugin.json; do
  jq -e . "$manifest" >/dev/null
done
marketplace_version=$(jq -r '.plugins[0].version' .claude-plugin/marketplace.json)
claude_version=$(jq -r '.version' .claude-plugin/plugin.json)
codex_version=$(jq -r '.version' .codex-plugin/plugin.json)
if [ "$marketplace_version" != "$claude_version" ] || [ "$claude_version" != "$codex_version" ]; then
  echo "error: native plugin manifest versions must match" >&2
  exit 1
fi

command -v claude >/dev/null 2>&1 || {
  echo "error: claude CLI is required for strict plugin validation" >&2
  exit 1
}
claude plugin validate --strict "$repo_root"
