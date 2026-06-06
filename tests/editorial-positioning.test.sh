#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failures=0

fail() {
  echo "$1" >&2
  failures=$((failures + 1))
}

require_pattern() {
  local file="$1"
  local pattern="$2"
  local description="$3"
  if ! grep -Eq -- "$pattern" "$file"; then
    fail "missing positioning evidence: $description"
  fi
}

forbid_pattern() {
  local file="$1"
  local pattern="$2"
  local description="$3"
  if grep -Eiq -- "$pattern" "$file"; then
    fail "forbidden positioning evidence: $description"
  fi
}

require_pattern "$repo_root/README.md" 'YOLKMEET is an operator-tech publication' "README describes operator-tech publication"
require_pattern "$repo_root/docs/editorial-system.md" 'operator-tech publication' "editorial system uses operator-tech model"
require_pattern "$repo_root/docs/content-pillar-map.md" 'YOLKMEET should not rely on a single AI-tools lane' "pillar map records not-AI-only rule"
require_pattern "$repo_root/content/templates/editorial-templates.md" '^# YOLKMEET Editorial Templates' "template docs use public brand casing"
require_pattern "$repo_root/content/templates/editorial-templates.md" 'related YOLKMEET guides' "template docs use public brand casing in internal-link rule"

for file in \
  "$repo_root/README.md" \
  "$repo_root/docs/editorial-system.md" \
  "$repo_root/docs/content-pillar-map.md" \
  "$repo_root/content/templates/editorial-templates.md"; do
  forbid_pattern "$file" 'English-first AI tools and automation WordPress publication' "old AI-only publication description in $(basename "$file")"
  forbid_pattern "$file" 'in today.s fast-paced digital landscape|revolutionize|unlock|seamless|leverage' "generic AI copy in $(basename "$file")"
done

if [ "$failures" -ne 0 ]; then
  echo "editorial positioning checks failed: $failures" >&2
  exit 1
fi

echo "editorial positioning checks passed: operator-tech model, YOLKMEET casing, and no generic AI positioning"
