#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: generate-post-publish-growth-brief.sh --candidate <markdown> --url <published-url> --output <brief.md>
EOF
}

candidate=""
published_url=""
output=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --candidate)
      candidate="${2:-}"
      shift 2
      ;;
    --url)
      published_url="${2:-}"
      shift 2
      ;;
    --output)
      output="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      echo "unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

[ -n "$candidate" ] || { usage; echo "missing --candidate" >&2; exit 2; }
[ -n "$published_url" ] || { usage; echo "missing --url" >&2; exit 2; }
[ -n "$output" ] || { usage; echo "missing --output" >&2; exit 2; }
[ -f "$candidate" ] || { echo "candidate not found: $candidate" >&2; exit 2; }

case "$published_url" in
  https://www.yolkmeet.com/*) ;;
  *)
    echo "published URL must be on https://www.yolkmeet.com/" >&2
    exit 2
    ;;
esac

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

front_matter_list() {
  local key="$1"
  awk -v key="$key" '
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { exit }
    in_fm && index($0, key ":") == 1 { in_list = 1; next }
    in_fm && in_list && $0 ~ /^[[:space:]]*-[[:space:]]+/ {
      item = $0
      sub(/^[[:space:]]*-[[:space:]]+/, "", item)
      gsub(/^"|"$/, "", item)
      print item
    }
    in_fm && $0 ~ /^[A-Za-z_][A-Za-z0-9_]*:/ && index($0, key ":") != 1 { in_list = 0 }
  ' "$candidate"
}

first_heading() {
  awk '
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { in_body = 1; next }
    in_body && /^# / {
      sub(/^# /, "")
      print
      exit
    }
  ' "$candidate"
}

title="$(front_matter_value title)"
[ -n "$title" ] || title="$(first_heading)"
[ -n "$title" ] || title="$(basename "$candidate" .md)"
slug="$(front_matter_value slug)"
target_keyword="$(front_matter_value target_keyword)"
generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

mkdir -p "$(dirname "$output")"

{
  printf '# Post-Publish Growth Brief: %s\n\n' "$title"
  printf -- '- Published URL: %s\n' "$published_url"
  printf -- '- Source candidate: %s\n' "$candidate"
  printf -- '- Generated at: %s\n\n' "$generated_at"

  printf '## Sitemap and Indexing\n'
  printf -- '- Sitemap check: confirm `%s` appears in `https://www.yolkmeet.com/sitemap.xml` after publish cache clears.\n' "$published_url"
  printf -- '- IndexNow check: confirm readiness for real publish/update/delete events; do not treat submission as an indexing guarantee.\n'
  printf -- '- Search Console checkpoint: record discovered, indexed, crawled-not-indexed, or error state when account data is available.\n'
  printf -- '- Bing Webmaster Tools checkpoint: record discovered, indexed, crawled-not-indexed, or error state when account data is available.\n\n'

  printf '## Internal Links\n'
  printf -- '- Candidate source pages:\n'
  if front_matter_list internal_links | grep -q .; then
    front_matter_list internal_links | sed 's/^/  - /'
  else
    printf '  - Review related category pages and recent YOLKMEET guides before adding links.\n'
  fi
  printf -- '- Anchor text suggestions: use the page topic, comparison target, or workflow outcome; avoid clickbait and ad-like calls to action.\n'
  printf -- '- Pages to avoid: unrelated YMYL pages, stale drafts, and pages that would create duplicate intent.\n\n'

  printf '## Refresh and Expansion\n'
  printf -- '- Title/meta rewrite trigger: impressions rise for two weekly reports while CTR or query fit stays weak.\n'
  printf -- '- Intro/answer-block rewrite trigger: query terms show a clearer reader problem than the current opening answer.\n'
  printf -- '- FAQ/table expansion trigger: source pages reveal a recurring constraint, pricing caveat, setup limit, or comparison dimension.\n'
  printf -- '- Source-update watch:\n'
  if front_matter_list source_urls | grep -q .; then
    front_matter_list source_urls | sed 's/^/  - /'
  else
    printf '  - Recheck the candidate source URLs before refreshing.\n'
  fi
  printf '\n'

  printf '## Manual Distribution Snippets\n'
  printf '### Short post\n'
  printf 'New YOLKMEET field guide: %s. It focuses on the decision criteria, source checks, and update assumptions operators should verify before adopting the workflow. %s\n\n' "$title" "$published_url"
  printf '### Community answer\n'
  printf 'If you are comparing this workflow, the useful starting point is not the longest feature list; it is the review gate, rollback path, and source freshness. I wrote up the checklist here: %s\n\n' "$published_url"
  printf '### LinkedIn-style note\n'
  printf 'A practical operator-tech page should make the tradeoffs visible: what changed, what source pages were checked, and what should be retested before a team depends on the workflow. This YOLKMEET guide covers that for %s: %s\n\n' "${target_keyword:-$slug}" "$published_url"

  printf '## Policy Guardrails\n'
  printf -- '- No proxy/VPN/artificial traffic.\n'
  printf -- '- No fake engagement.\n'
  printf -- '- No automated account posting.\n'
  printf -- '- No request for ad clicks.\n'
  printf -- '- Manual review required before any external distribution.\n'
} >"$output"

printf 'growth brief written: %s\n' "$output"
