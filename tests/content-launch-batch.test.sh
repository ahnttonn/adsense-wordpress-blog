#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
articles_file="$repo_root/content/launch-batch/articles.tsv"
publish_script="$repo_root/infra/publish-launch-batch.sh"
quality_gate="$repo_root/infra/content-quality-gate.sh"
fixture_dir="$repo_root/tests/fixtures/content-quality"
failures=0

fail() {
  echo "$1" >&2
  failures=$((failures + 1))
}

assert_file() {
  local path="$1"
  local description="$2"

  if [ ! -f "$path" ]; then
    fail "missing $description: $path"
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local description="$3"

  if ! printf '%s' "$haystack" | grep -Fq -- "$needle"; then
    fail "missing content launch evidence: $description"
  fi
}

assert_file "$articles_file" "launch article manifest"
assert_file "$publish_script" "WordPress launch batch publisher"
assert_file "$quality_gate" "content quality gate"

if [ -f "$articles_file" ]; then
  article_count="$(awk -F '\t' 'NR > 1 && NF > 0 { count++ } END { print count + 0 }' "$articles_file")"
  if [ "$article_count" -lt 30 ]; then
    fail "expected at least 30 launch articles, got $article_count"
  fi

  awk -F '\t' '
    NR == 1 { next }
    NF > 0 {
      if (NF != 13) {
        printf "row %d expected 13 fields, got %d\n", NR, NF
        bad = 1
        next
      }
      sources_count = split($9, sources, "\\|")
      links_count = split($10, links, "\\|")
      if ($1 == "" || $2 == "" || $3 == "" || $4 == "" || $5 == "" || $6 == "" || $7 == "" || $8 == "" || $9 == "" || $10 == "" || $11 == "" || $12 == "" || $13 == "") {
        printf "row %d has an empty required field\n", NR
        bad = 1
      }
      if (length($5) > 62) {
        printf "row %d meta title too long: %d\n", NR, length($5)
        bad = 1
      }
      if (length($6) < 60 || length($6) > 165) {
        printf "row %d meta description length out of range: %d\n", NR, length($6)
        bad = 1
      }
      if (sources_count < 2) {
        printf "row %d needs at least two source URLs\n", NR
        bad = 1
      }
      if (links_count < 2) {
        printf "row %d needs at least two internal link slugs\n", NR
        bad = 1
      }
      if ($11 !~ /Source-derived analysis/) {
        printf "row %d analysis note must clearly mark source-derived analysis\n", NR
        bad = 1
      }
    }
    END { exit bad ? 1 : 0 }
  ' "$articles_file" || fail "article manifest failed required-field validation"
fi

if [ -f "$publish_script" ]; then
  publish_body="$(sed -n '1,260p' "$publish_script")"
  assert_contains "$publish_body" "wp --path=" "publisher uses WP-CLI with explicit path"
  assert_contains "$publish_body" "post create" "publisher creates posts"
  assert_contains "$publish_body" "_yolkmeet_source_urls" "publisher records source URLs"
  assert_contains "$publish_body" "_yolkmeet_target_keyword" "publisher records target keyword"
  assert_contains "$publish_body" "_yolkmeet_originality_checklist" "publisher records originality checklist"
  assert_contains "$publish_body" "_yolkmeet_update_policy" "publisher records update policy"
fi

if [ -f "$quality_gate" ] && [ -d "$fixture_dir" ]; then
  if bash "$quality_gate" "$fixture_dir/original-draft.md" >/dev/null 2>&1; then
    :
  else
    fail "content quality gate rejected original-draft.md"
  fi

  if bash "$quality_gate" "$fixture_dir/copied-draft.md" >/dev/null 2>&1; then
    fail "content quality gate allowed copied-draft.md"
  else
    echo "copied-draft blocked"
  fi

  if bash "$quality_gate" "$fixture_dir/malformed-front-matter.md" >/dev/null 2>&1; then
    fail "content quality gate allowed malformed-front-matter.md"
  fi

  if bash "$quality_gate" "$fixture_dir/prompt-injection-draft.md" >/dev/null 2>&1; then
    :
  else
    fail "content quality gate followed or mishandled prompt-injection-draft.md"
  fi

  if bash "$quality_gate" "$fixture_dir/missing.md" >/dev/null 2>&1; then
    fail "content quality gate allowed missing file"
  fi
fi

if [ "$failures" -ne 0 ]; then
  echo "Content launch batch checks failed: $failures" >&2
  exit 1
fi

echo "Content launch batch checks passed: manifest, publisher contract, and content quality gate"
