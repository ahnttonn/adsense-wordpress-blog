#!/usr/bin/env bash
set -euo pipefail

candidate="${1:-}"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture_source_dir="$repo_root/tests/fixtures/content-quality/sources"
launch_manifest="$repo_root/content/launch-batch/articles.tsv"

fail() {
  echo "blocked: $1" >&2
  exit "${2:-1}"
}

trim() {
  sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

normalize() {
  tr '[:upper:]' '[:lower:]' |
    tr -cs 'a-z0-9' ' ' |
    sed 's/[[:space:]]\{1,\}/ /g; s/^ //; s/ $//'
}

word_count() {
  awk '{ total += NF } END { print total + 0 }'
}

validate_launch_manifest() {
  [ -f "$launch_manifest" ] || return 0

  awk -F '\t' '
    NR == 1 {
      expected = "id\tslug\tcategory\ttarget_keyword\tmeta_title\tmeta_description\tsource_urls\tinternal_links\tarticle_type\tanalysis_note\tupdate_policy\teditorial_notes\tstatus"
      current = "slug\ttitle\tcategory\ttarget_keyword\tmeta_title\tmeta_description\ttemplate\tupdate_policy\tsource_urls\tinternal_link_targets\tanalysis_note\tevidence_note\tdecision"
      if ($0 == expected) {
        mode = "legacy"
      } else if ($0 == current) {
        mode = "current"
      } else {
        printf "launch manifest header mismatch\n" > "/dev/stderr"
        bad = 1
      }
      next
    }
    NF > 0 {
      if (NF != 13) {
        printf "row %d expected 13 fields, got %d\n", NR, NF > "/dev/stderr"
        bad = 1
        next
      }
      slug_field = mode == "legacy" ? $2 : $1
      meta_title_field = mode == "legacy" ? $5 : $5
      meta_description_field = mode == "legacy" ? $6 : $6
      sources_field = mode == "legacy" ? $7 : $9
      links_field = mode == "legacy" ? $8 : $10
      analysis_field = mode == "legacy" ? $10 : $11
      update_field = mode == "legacy" ? $11 : $8
      sources_count = split(sources_field, sources, "|")
      links_count = split(links_field, links, "|")
      for (i = 1; i <= 13; i++) {
        if ($i == "") {
          printf "row %d has an empty required field\n", NR > "/dev/stderr"
          bad = 1
        }
      }
      if (slug_field !~ /^[a-z0-9]+(-[a-z0-9]+)*$/) {
        printf "row %d has invalid slug: %s\n", NR, slug_field > "/dev/stderr"
        bad = 1
      }
      if (length(meta_title_field) > 62) {
        printf "row %d meta title too long: %d\n", NR, length(meta_title_field) > "/dev/stderr"
        bad = 1
      }
      if (length(meta_description_field) < 60 || length(meta_description_field) > 165) {
        printf "row %d meta description length out of range: %d\n", NR, length(meta_description_field) > "/dev/stderr"
        bad = 1
      }
      if (sources_count < 2) {
        printf "row %d needs at least two source URLs\n", NR > "/dev/stderr"
        bad = 1
      }
      if (links_count < 2) {
        printf "row %d needs at least two internal link slugs\n", NR > "/dev/stderr"
        bad = 1
      }
      if (analysis_field !~ /Source-derived analysis/) {
        printf "row %d analysis note must mark source-derived analysis\n", NR > "/dev/stderr"
        bad = 1
      }
      if (update_field !~ /[Uu]pdate|Refresh/) {
        printf "row %d update policy must describe updates\n", NR > "/dev/stderr"
        bad = 1
      }
      rows++
    }
    END {
      if (rows < 1) {
        printf "launch manifest has no article rows\n" > "/dev/stderr"
        bad = 1
      }
      exit bad ? 1 : 0
    }
  ' "$launch_manifest" || fail "launch-batch metadata validation failed"
}

front_matter_value() {
  local key="$1"
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
  ' "$candidate"
}

front_matter_list_count() {
  local key="$1"
  awk -v key="$key" '
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { print count + 0; exit }
    in_fm && $0 ~ /^[A-Za-z_][A-Za-z0-9_]*:/ { in_list = 0 }
    in_fm && index($0, key ":") == 1 { in_list = 1; next }
    in_fm && in_list && $0 ~ /^[[:space:]]*-[[:space:]]+/ { count++ }
    END { if (in_fm) print count + 0 }
  ' "$candidate" | tail -n 1
}

validate_front_matter_shape() {
  local malformed
  malformed="$(
    awk '
      NR == 1 && $0 == "---" { in_fm = 1; next }
      in_fm && $0 == "---" { exit }
      in_fm && $0 == "" { next }
      in_fm && $0 ~ /^[[:space:]]*-/ { next }
      in_fm && $0 !~ /^[A-Za-z_][A-Za-z0-9_]*:[[:space:]]*/ {
        print NR ":" $0
        exit
      }
    ' "$candidate"
  )"
  [ -z "$malformed" ] || fail "malformed front matter at $malformed"
}

validate_required_metadata() {
  local key value
  for key in title slug target_keyword meta_title meta_description; do
    value="$(front_matter_value "$key" | trim)"
    [ -n "$value" ] || fail "missing required front matter: $key"
  done

  value="$(front_matter_value slug)"
  printf '%s' "$value" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$' || fail "slug must be lowercase hyphenated text"

  value="$(front_matter_value meta_title)"
  [ "${#value}" -le 62 ] || fail "meta_title exceeds 62 characters"

  value="$(front_matter_value meta_description)"
  [ "${#value}" -ge 60 ] && [ "${#value}" -le 165 ] || fail "meta_description must be 60-165 characters"

  value="$(front_matter_value analysis_note || true)"
  if [ -n "$value" ]; then
    printf '%s' "$value" | grep -Fq 'Source-derived analysis' || fail "analysis_note must mark Source-derived analysis"
  else
    [ "$(front_matter_list_count source_log)" -ge 2 ] || fail "analysis_note or source_log must mark source-derived evidence"
  fi

  value="$(front_matter_value update_policy || true)"
  if [ -z "$value" ]; then
    value="$(front_matter_value update_cadence || true)"
  fi
  [ -n "$value" ] || fail "missing required front matter: update_policy or update_cadence"
  printf '%s' "$value" | grep -Eiq 'update|review|refresh|recheck' || fail "update policy must describe update handling"

  local source_count
  source_count="$(front_matter_list_count source_urls)"
  if [ "$source_count" -lt 2 ]; then
    source_count="$(front_matter_list_count source_log)"
  fi
  [ "$source_count" -ge 2 ] || fail "need at least two source URLs or source_log entries"

  [ "$(front_matter_list_count internal_links)" -ge 2 ] || fail "need at least two internal_links"
}

validate_originality() {
  [ -d "$fixture_source_dir" ] || return 0

  local normalized_candidate source words
  normalized_candidate="$(normalize <"$candidate")"
  [ "$(printf '%s\n' "$normalized_candidate" | word_count)" -ge 35 ] || fail "draft body and metadata are too short for launch QA"

  while IFS= read -r source; do
    [ -f "$source" ] || continue
    while IFS= read -r paragraph; do
      paragraph="$(printf '%s' "$paragraph" | trim)"
      [ -n "$paragraph" ] || continue
      words="$(printf '%s\n' "$paragraph" | word_count)"
      [ "$words" -ge 12 ] || continue
      if printf '%s\n' "$normalized_candidate" | grep -Fq -- "$(printf '%s' "$paragraph" | normalize)"; then
        fail "copied paragraph matches local source fixture: $(basename "$source")"
      fi
    done <"$source"
  done < <(find "$fixture_source_dir" -type f -name '*.txt' -print | sort)
}

if [ -z "$candidate" ]; then
  fail "usage: $0 <markdown-file>" 2
fi

[ -f "$candidate" ] || fail "missing file: $candidate" 2
[ -r "$candidate" ] || fail "unreadable file: $candidate" 2

if [ "$(sed -n '1p' "$candidate")" != "---" ]; then
  fail "missing YAML-style front matter"
fi

if ! awk 'NR > 1 && $0 == "---" { found = 1; exit } END { exit found ? 0 : 1 }' "$candidate"; then
  fail "front matter is not closed"
fi

validate_front_matter_shape
validate_required_metadata
validate_originality
validate_launch_manifest

echo "content quality gate passed: $(basename "$candidate")"
