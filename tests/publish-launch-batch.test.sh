#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo_root/infra/publish-launch-batch.sh"
manifest="$repo_root/content/launch-batch/articles.tsv"
failures=0

fail() {
  echo "$1" >&2
  failures=$((failures + 1))
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local description="$3"

  if ! printf '%s' "$haystack" | grep -Fq -- "$needle"; then
    fail "missing publish launch batch evidence: $description"
  fi
}

if [ ! -f "$script" ]; then
  fail "missing publisher script: $script"
else
  bash -n "$script" || fail "publisher script syntax failed"
  body="$(sed -n '1,280p' "$script")"
  assert_contains "$body" "wp --path=" "WP-CLI path is explicit"
  assert_contains "$body" "post create" "creates missing posts"
  assert_contains "$body" "post update" "updates existing posts idempotently"
  assert_contains "$body" "_yolkmeet_source_urls" "source URL metadata"
  assert_contains "$body" "_yolkmeet_primary_keyword" "primary keyword metadata"
  assert_contains "$body" "_yolkmeet_target_keyword" "target keyword metadata"
  assert_contains "$body" "_yolkmeet_last_reviewed" "last reviewed metadata"
  assert_contains "$body" "_yolkmeet_meta_title" "meta title metadata"
  assert_contains "$body" "_yolkmeet_meta_description" "meta description metadata"
  assert_contains "$body" "_yolkmeet_originality_checklist" "originality checklist metadata"
  assert_contains "$body" "_yolkmeet_update_policy" "update policy metadata"
  assert_contains "$body" "cache flush" "cache flush after publish"
fi

if [ -f "$manifest" ]; then
  count="$(awk -F '\t' 'NR > 1 && NF == 13 { count++ } END { print count + 0 }' "$manifest")"
  [ "$count" -ge 30 ] || fail "manifest must include at least 30 publishable rows"
fi

if [ "$failures" -ne 0 ]; then
  echo "publish launch batch checks failed: $failures" >&2
  exit 1
fi

echo "publish launch batch checks passed"
