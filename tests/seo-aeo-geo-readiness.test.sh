#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture_root="$repo_root/tests/fixtures/seo-aeo-geo"

fail() {
  echo "blocked: $1" >&2
  exit "${2:-1}"
}

front_matter_value() {
  local file="$1"
  local key="$2"
  awk -v key="$key" '
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { exit }
    in_fm && index($0, key ":") == 1 {
      value = substr($0, length(key) + 2)
      sub(/^[[:space:]]+/, "", value)
      sub(/[[:space:]]+$/, "", value)
      gsub(/^"|"$/, "", value)
      print value
      exit
    }
  ' "$file"
}

front_matter_list_count() {
  local file="$1"
  local key="$2"
  awk -v key="$key" '
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { print count + 0; exit }
    in_fm && $0 ~ /^[A-Za-z_][A-Za-z0-9_]*:/ { in_list = 0 }
    in_fm && index($0, key ":") == 1 { in_list = 1; next }
    in_fm && in_list && $0 ~ /^[[:space:]]*-[[:space:]]+/ { count++ }
    END { if (in_fm) print count + 0 }
  ' "$file" | tail -n 1
}

body_text() {
  local file="$1"
  awk '
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { in_fm = 0; body = 1; next }
    !in_fm && body { print }
  ' "$file"
}

validate_metadata() {
  local file="$1"
  local key value

  [ "$(sed -n '1p' "$file")" = "---" ] || fail "missing YAML-style front matter"
  awk 'NR > 1 && $0 == "---" { found = 1; exit } END { exit found ? 0 : 1 }' "$file" || fail "front matter is not closed"

  for key in title target_keyword meta_title meta_description; do
    value="$(front_matter_value "$file" "$key")"
    [ -n "$value" ] || fail "missing required front matter: $key"
  done

  value="$(front_matter_value "$file" "meta_title")"
  [ "${#value}" -le 62 ] || fail "SEO Gate failed: meta_title exceeds 62 characters"

  value="$(front_matter_value "$file" "meta_description")"
  [ "${#value}" -ge 60 ] && [ "${#value}" -le 165 ] || fail "SEO Gate failed: meta_description must be 60-165 characters"
}

validate_sources_and_links() {
  local file="$1"
  local source_count source_url_count internal_link_count

  source_count="$(front_matter_list_count "$file" "source_log")"
  source_url_count="$(front_matter_list_count "$file" "source_urls")"
  if [ "$source_url_count" -gt "$source_count" ]; then
    source_count="$source_url_count"
  fi
  [ "$source_count" -ge 2 ] || fail "SEO Gate failed: need at least two source_log or source_urls entries"

  internal_link_count="$(front_matter_list_count "$file" "internal_links")"
  [ "$internal_link_count" -ge 2 ] || fail "SEO Gate failed: need at least two internal_links entries"
}

validate_answer_block() {
  local file="$1"
  local top_window

  top_window="$(
    body_text "$file" |
      sed -n '1,40p'
  )"

  printf '%s\n' "$top_window" | grep -Eiq '^(##[[:space:]]+(Quick Answer|Short Answer)|\*\*(Short answer|Quick answer):\*\*)' || \
    fail "AEO Gate failed: missing answer block near the top"
}

validate_body_structure() {
  local file="$1"
  local body
  body="$(body_text "$file")"

  printf '%s\n' "$body" | grep -Eq '^\|.+\|.+\|$' || printf '%s\n' "$body" | grep -Eq '^[[:space:]]*-[[:space:]]\[[ xX]\]' || \
    fail "SEO Gate failed: need a comparison table or checklist"

  printf '%s\n' "$body" | grep -Eiq '^(##|###)[[:space:]]+(FAQ|Frequently Asked Questions|Questions|Common Questions|Which |What |When |Why |How )' || \
    fail "AEO Gate failed: missing FAQ or question-led section"

  printf '%s\n' "$body" | grep -Eiq '(Update note|update cadence|refresh after|review notes|update log)' || \
    [ -n "$(front_matter_value "$file" "update_cadence")" ] || \
    [ -n "$(front_matter_value "$file" "update_policy")" ] || \
    fail "SEO Gate failed: missing update note or cadence"
}

validate_geo_signals() {
  local file="$1"
  local body
  body="$(body_text "$file")"

  printf '%s\n' "$body" | grep -Eiq '\b(best fit|choose|pick|decision criteria|use this when|better choice)\b' || \
    fail "GEO Gate failed: missing decision-ready language"

  printf '%s\n' "$body" | grep -Eiq '\b(n8n|zapier|make|pipedream|wordpress|google adsense|chatgpt)\b' || \
    fail "GEO Gate failed: missing named entities"

  printf '%s\n' "$body" | grep -Eiq '(source notes|source log|citation|official docs|checked 20[0-9]{2}-[0-9]{2}-[0-9]{2})' || \
    fail "GEO Gate failed: missing visible source notes or citation language"
}

check_file() {
  local file="$1"
  [ -f "$file" ] || fail "missing file: $file" 2
  [ -r "$file" ] || fail "unreadable file: $file" 2

  validate_metadata "$file"
  validate_sources_and_links "$file"
  validate_answer_block "$file"
  validate_body_structure "$file"
  validate_geo_signals "$file"

  echo "SEO/AEO/GEO readiness checks passed: $(basename "$file")"
}

expect_failure() {
  local file="$1"
  local expected="$2"
  local output

  set +e
  output="$(bash "$0" "$file" 2>&1)"
  status=$?
  set -e

  if [ "$status" -eq 0 ]; then
    fail "expected failure for $(basename "$file")"
  fi

  printf '%s\n' "$output" | grep -Fq -- "$expected" || fail "expected error '$expected' for $(basename "$file")"
}

if [ "$#" -gt 1 ]; then
  fail "usage: $0 [markdown-file]" 2
fi

if [ "$#" -eq 1 ]; then
  check_file "$1"
  exit 0
fi

check_file "$fixture_root/good/n8n-alternatives-ready.md"
expect_failure "$fixture_root/bad/missing-source-notes.md" "SEO Gate failed: need at least two source_log or source_urls entries"
expect_failure "$fixture_root/bad/missing-answer-block.md" "AEO Gate failed: missing answer block near the top"
expect_failure "$fixture_root/bad/malformed-front-matter.md" "missing YAML-style front matter"

echo "SEO/AEO/GEO readiness fixture checks passed: good fixture accepted, source-note and answer-block regressions rejected"
