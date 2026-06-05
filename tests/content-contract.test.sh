#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
manifest="$repo_root/content/launch-batch/articles.tsv"
article_dir="$repo_root/content/launch-batch"
template_dir="$repo_root/content/templates"
quality_gate="$repo_root/infra/content-quality-gate.sh"
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

assert_dir() {
  local path="$1"
  local description="$2"

  if [ ! -d "$path" ]; then
    fail "missing $description: $path"
  fi
}

assert_file "$manifest" "launch article manifest"
assert_dir "$article_dir" "launch article directory"
assert_dir "$template_dir" "template directory"
assert_file "$quality_gate" "content quality gate"

template_count="$(find "$template_dir" -maxdepth 1 -name '*template*.md' | wc -l | tr -d ' ')"
if [ "$template_count" -lt 7 ]; then
  fail "expected at least 7 editorial templates, got $template_count"
fi

article_count="$(find "$article_dir" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')"
if [ "$article_count" -lt 30 ]; then
  fail "expected at least 30 markdown launch articles, got $article_count"
fi

if [ -f "$manifest" ]; then
  manifest_count="$(awk -F '\t' 'NR > 1 && NF > 0 { count++ } END { print count + 0 }' "$manifest")"
  if [ "$manifest_count" -lt 30 ]; then
    fail "expected at least 30 manifest rows, got $manifest_count"
  fi

  awk -F '\t' '
    NR == 1 {
      expected = "slug\ttitle\tcategory\ttarget_keyword\tmeta_title\tmeta_description\ttemplate\tupdate_policy\tsource_urls\tinternal_link_targets\tanalysis_note\tevidence_note\tdecision"
      if ($0 != expected) {
        printf "manifest header mismatch\n"
        bad = 1
      }
      next
    }
    NF > 0 {
      rows++
      if (NF != 13) {
        printf "row %d expected 13 fields, got %d\n", NR, NF
        bad = 1
        next
      }
      source_count = split($9, sources, "|")
      link_count = split($10, links, "|")
      if ($1 !~ /^[a-z0-9]+(-[a-z0-9]+)*$/) {
        printf "row %d slug is not kebab-case: %s\n", NR, $1
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
      if (source_count < 2) {
        printf "row %d needs at least two source URLs\n", NR
        bad = 1
      }
      if (link_count < 2) {
        printf "row %d needs at least two internal link targets\n", NR
        bad = 1
      }
      if ($11 !~ /Source-derived analysis/) {
        printf "row %d analysis note must mark Source-derived analysis\n", NR
        bad = 1
      }
      for (i = 1; i <= 13; i++) {
        if ($i == "") {
          printf "row %d field %d is empty\n", NR, i
          bad = 1
        }
      }
    }
    END {
      if (rows < 30) {
        printf "expected at least 30 launch rows, got %d\n", rows + 0
        bad = 1
      }
      exit bad ? 1 : 0
    }
  ' "$manifest" || fail "article manifest failed launch content contract validation"
fi

while IFS= read -r article_path; do
  if ! bash "$quality_gate" "$article_path" >/dev/null 2>&1; then
    fail "quality gate rejected launch article: $article_path"
    continue
  fi

  slug="$(awk '
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { exit }
    in_fm && /^slug:/ {
      value = substr($0, 6)
      gsub(/^[[:space:]"]+|[[:space:]"]+$/, "", value)
      print value
      exit
    }
  ' "$article_path")"

  if [ "$slug" = "" ]; then
    fail "article missing slug: $article_path"
    continue
  fi

  for section in "## Quick Answer" "## Source Log" "## Internal Link Plan" "## Review Notes"; do
    if ! grep -Fq -- "$section" "$article_path"; then
      fail "article $slug missing section: $section"
    fi
  done

  if grep -Eiq -- 'TODO|lorem|as an AI|I cannot|copied from' "$article_path"; then
    fail "article $slug contains placeholder or AI-refusal text"
  fi
done < <(find "$article_dir" -maxdepth 1 -name '*.md' | sort)

if [ "$failures" -ne 0 ]; then
  echo "Content contract checks failed: $failures" >&2
  exit 1
fi

echo "Content contract checks passed: manifest, templates, 30+ articles, source logs, originality metadata, and quality gate"
