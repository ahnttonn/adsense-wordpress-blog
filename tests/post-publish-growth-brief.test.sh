#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo_root/infra/generate-post-publish-growth-brief.sh"
fixture="$repo_root/tests/fixtures/hourly-publishing/valid-draft.md"
tmp_dir="${TMPDIR:-/tmp}/yolkmeet-growth-brief-test-$$"
failures=0

fail() {
  echo "$1" >&2
  failures=$((failures + 1))
}

require_file() {
  local file="$1"
  local description="$2"
  [ -f "$file" ] || fail "missing growth brief file: $description"
}

require_pattern() {
  local file="$1"
  local pattern="$2"
  local description="$3"
  if ! grep -Eq -- "$pattern" "$file"; then
    fail "missing growth brief evidence: $description"
  fi
}

forbid_bad_action() {
  local file="$1"
  if grep -Eiq 'buy traffic|traffic exchange|rotate prox|click ads|auto-post to|generate fake engagement|create fake engagement|bot traffic' "$file"; then
    fail "growth brief contains unsafe acquisition action"
  fi
}

trap 'rm -rf "$tmp_dir"' EXIT
mkdir -p "$tmp_dir"

require_file "$repo_root/content/distribution-queue/ready/.gitkeep" "ready queue placeholder"
require_file "$repo_root/content/distribution-queue/processed/.gitkeep" "processed queue placeholder"
require_file "$repo_root/content/distribution-queue/blocked/.gitkeep" "blocked queue placeholder"
require_file "$script" "growth brief generator"

if [ -f "$script" ]; then
  bash -n "$script" || fail "growth brief generator shell syntax"
fi

output="$tmp_dir/growth-brief.md"
if ! bash "$script" \
  --candidate "$fixture" \
  --url "https://www.yolkmeet.com/workflow-automation/hourly-publishing-valid-draft/" \
  --output "$output" >"$tmp_dir/generate.out" 2>"$tmp_dir/generate.err"; then
  sed -n '1,120p' "$tmp_dir/generate.err" >&2
  fail "growth brief generator failed valid fixture"
fi

if [ -f "$output" ]; then
  require_pattern "$output" '^# Post-Publish Growth Brief: Hourly Publishing Valid Draft$' "title"
  require_pattern "$output" 'Published URL: https://www\.yolkmeet\.com/workflow-automation/hourly-publishing-valid-draft/' "published URL"
  require_pattern "$output" '^## Sitemap and Indexing$' "sitemap/indexing section"
  require_pattern "$output" '^## Internal Links$' "internal links section"
  require_pattern "$output" '^## Refresh and Expansion$' "refresh section"
  require_pattern "$output" '^## Manual Distribution Snippets$' "manual snippets section"
  require_pattern "$output" '^## Policy Guardrails$' "policy guardrails section"
  require_pattern "$output" 'Manual review required before any external distribution' "manual review guardrail"
  require_pattern "$output" 'No proxy/VPN/artificial traffic' "artificial traffic prohibition"
  forbid_bad_action "$output"
else
  fail "growth brief output was not created"
fi

if bash "$script" --candidate "$tmp_dir/missing.md" --url "https://www.yolkmeet.com/x/" --output "$tmp_dir/missing-output.md" >"$tmp_dir/missing.out" 2>"$tmp_dir/missing.err"; then
  fail "missing candidate unexpectedly succeeded"
fi

if bash "$script" --candidate "$fixture" --output "$tmp_dir/no-url.md" >"$tmp_dir/no-url.out" 2>"$tmp_dir/no-url.err"; then
  fail "missing URL unexpectedly succeeded"
fi

if [ "$failures" -ne 0 ]; then
  echo "post-publish growth brief checks failed: $failures" >&2
  exit 1
fi

echo "post-publish growth brief checks passed: queue dirs, required sections, failure paths, and no unsafe acquisition actions"
