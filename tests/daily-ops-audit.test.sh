#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
doc="$repo_root/docs/daily-ops-audit.md"
script="$repo_root/infra/daily-ops-audit.sh"
tmp_dir="${TMPDIR:-/tmp}/yolkmeet-daily-ops-test-$$"
failures=0

fail() {
  echo "$1" >&2
  failures=$((failures + 1))
}

require_file() {
  local file="$1"
  local description="$2"
  [ -f "$file" ] || fail "missing daily ops artifact: $description"
}

require_pattern() {
  local file="$1"
  local pattern="$2"
  local description="$3"
  if ! grep -Eq -- "$pattern" "$file"; then
    fail "missing daily ops evidence: $description"
  fi
}

forbid_pattern() {
  local file="$1"
  local pattern="$2"
  local description="$3"
  if grep -Eiq -- "$pattern" "$file"; then
    fail "forbidden daily ops behavior: $description"
  fi
}

trap 'rm -rf "$tmp_dir"' EXIT
mkdir -p "$tmp_dir/evidence"

require_file "$doc" "daily ops docs"
require_file "$script" "daily ops read-only script"

if [ -f "$script" ]; then
  bash -n "$script" || fail "daily ops script shell syntax"
fi

if [ -f "$doc" ]; then
  require_pattern "$doc" 'read-only by default' "read-only boundary"
  require_pattern "$doc" 'create an ULW plan only if' "plan-only escalation"
  require_pattern "$doc" 'must not mutate WordPress' "no production mutation"
  require_pattern "$doc" 'content/distribution-queue/ready' "distribution brief review queue"
  require_pattern "$doc" 'Search Visibility Watch' "search visibility watch section"
  require_pattern "$doc" 'Search Console and Bing Webmaster Tools' "official search tools boundary"
  require_pattern "$doc" 'must not scrape search result pages' "no SERP scraping boundary"
fi

if [ -f "$script" ]; then
  forbid_pattern "$script" 'wp post update|wp post create|wp option update|publish-hourly-payload|git push|git commit|google\.com/search|bing\.com/search|SERP scrape' "mutation or SERP scraping command in read-only audit"
  YOLKMEET_DAILY_OPS_SKIP_HTTP=1 YOLKMEET_DAILY_OPS_EVIDENCE_DIR="$tmp_dir/evidence" bash "$script" >"$tmp_dir/run.out" 2>"$tmp_dir/run.err" || fail "daily ops audit script failed"
  find "$tmp_dir/evidence" -type f -name '*summary.md' -print -quit | grep -q . || fail "daily ops summary evidence missing"
  search_watch_file="$(find "$tmp_dir/evidence" -type f -name '*search-visibility-watch.md' -print -quit)"
  [ -n "$search_watch_file" ] || fail "search visibility watch evidence missing"
  if [ -n "$search_watch_file" ]; then
    require_pattern "$search_watch_file" 'site:yolkmeet\.com' "site search spot-check query"
    require_pattern "$search_watch_file" 'Search Console URL Inspection' "Google inspection reminder"
    require_pattern "$search_watch_file" 'Bing URL Inspection' "Bing inspection reminder"
    require_pattern "$search_watch_file" 'Do not automate repeated search-result scraping' "no repeated SERP scraping reminder"
  fi
  grep -Fq 'HTTP checks skipped by YOLKMEET_DAILY_OPS_SKIP_HTTP=1' "$tmp_dir/run.out" || fail "skip-http mode not observable"
fi

if [ "$failures" -ne 0 ]; then
  echo "daily ops audit checks failed: $failures" >&2
  exit 1
fi

echo "daily ops audit checks passed: docs, read-only script, evidence output, and no mutation commands"
