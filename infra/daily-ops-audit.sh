#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
evidence_dir="${YOLKMEET_DAILY_OPS_EVIDENCE_DIR:-$repo_root/.omo/evidence/daily-ops}"
base_url="${YOLKMEET_DAILY_OPS_BASE_URL:-https://www.yolkmeet.com}"
today="$(date -u +%Y-%m-%d)"

mkdir -p "$evidence_dir"

write_count() {
  local dir="$1"
  local label="$2"
  if [ -d "$dir" ]; then
    printf '%s=%s\n' "$label" "$(find "$dir" -maxdepth 1 -type f ! -name '.gitkeep' | wc -l | tr -d ' ')"
  else
    printf '%s=missing\n' "$label"
  fi
}

http_head() {
  local url="$1"
  local output="$2"
  if [ "${YOLKMEET_DAILY_OPS_SKIP_HTTP:-0}" = "1" ]; then
    printf 'HTTP checks skipped by YOLKMEET_DAILY_OPS_SKIP_HTTP=1\n' | tee "$output"
    return 0
  fi
  curl -i --max-time 20 "$url" >"$output" 2>&1 || true
}

write_search_visibility_watch() {
  local output="$1"
  {
    printf '# Search Visibility Watch\n\n'
    printf 'Use official account data as the source of truth, then record a small manual search spot-check.\n\n'
    printf '## Official tools\n\n'
    printf -- '- Search Console URL Inspection: check the newest published URLs for Google indexing status, crawlability, canonical, and page fetch issues.\n'
    printf -- '- Bing URL Inspection: check the newest published URLs for Bing index status, crawl issues, SEO issues, and markup issues.\n'
    printf -- '- Bing IndexNow: confirm recent publish/update activity is visible in Bing Webmaster Tools when submissions are enabled.\n\n'
    printf '## Manual search spot-check queries\n\n'
    printf -- '- site:yolkmeet.com\n'
    printf -- '- site:yolkmeet.com "YOLKMEET"\n'
    printf -- '- site:yolkmeet.com "Operator-tech field guides"\n'
    find "$repo_root/content/hourly-queue/processed" "$repo_root/content/hourly-queue/ready" \
      -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort -r | head -n 5 | while IFS= read -r candidate; do
        title="$(sed -n 's/^title:[[:space:]]*"\(.*\)"[[:space:]]*$/\1/p' "$candidate" | head -n 1)"
        if [ -n "$title" ]; then
          printf -- '- site:yolkmeet.com "%s"\n' "$title"
        fi
      done
    printf '\n## Guardrails\n\n'
    printf -- '- Do not automate repeated search-result scraping. Use this file as a manual checklist unless an approved search API is configured later.\n'
    printf -- '- Do not treat a missing search result as a content failure on the first day. Inspect the URL in Search Console and Bing Webmaster Tools first.\n'
    printf -- '- If a URL is missing after repeated official-tool checks, create a bounded ULW plan before changing content, sitemap, canonical, robots, or IndexNow behavior.\n'
  } >"$output"
}

{
  write_count "$repo_root/content/hourly-queue/ready" "hourly_ready"
  write_count "$repo_root/content/hourly-queue/processed" "hourly_processed"
  write_count "$repo_root/content/hourly-queue/blocked" "hourly_blocked"
  write_count "$repo_root/content/distribution-queue/ready" "distribution_ready"
  write_count "$repo_root/content/distribution-queue/processed" "distribution_processed"
  write_count "$repo_root/content/distribution-queue/blocked" "distribution_blocked"
} >"$evidence_dir/$today-queue-counts.txt"

cron_log="$repo_root/.omo/evidence/hourly-publishing-cron/cron.log"
if [ -f "$cron_log" ]; then
  tail -n 80 "$cron_log" >"$evidence_dir/$today-hourly-cron-log-tail.txt"
else
  printf 'hourly cron log missing: %s\n' "$cron_log" >"$evidence_dir/$today-hourly-cron-log-tail.txt"
fi

find "$repo_root/content/distribution-queue/ready" -maxdepth 1 -type f ! -name '.gitkeep' 2>/dev/null | sort >"$evidence_dir/$today-distribution-ready-files.txt" || true
write_search_visibility_watch "$evidence_dir/$today-search-visibility-watch.md"

http_head "$base_url/" "$evidence_dir/$today-homepage-http.txt"
http_head "$base_url/sitemap.xml" "$evidence_dir/$today-sitemap-http.txt"
http_head "$base_url/robots.txt" "$evidence_dir/$today-robots-http.txt"
http_head "$base_url/about/" "$evidence_dir/$today-about-http.txt"
http_head "$base_url/privacy/" "$evidence_dir/$today-privacy-http.txt"

{
  printf '# Daily Ops Audit Summary\n\n'
  printf -- '- UTC date: %s\n' "$today"
  printf -- '- Base URL: %s\n' "$base_url"
  printf -- '- Queue counts: `%s`\n' "$evidence_dir/$today-queue-counts.txt"
  printf -- '- Cron log tail: `%s`\n' "$evidence_dir/$today-hourly-cron-log-tail.txt"
  printf -- '- Distribution ready files: `%s`\n' "$evidence_dir/$today-distribution-ready-files.txt"
  printf -- '- Search visibility watch: `%s`\n' "$evidence_dir/$today-search-visibility-watch.md"
  printf -- '- Homepage HTTP: `%s`\n' "$evidence_dir/$today-homepage-http.txt"
  printf -- '- Sitemap HTTP: `%s`\n' "$evidence_dir/$today-sitemap-http.txt"
  printf -- '- Robots HTTP: `%s`\n' "$evidence_dir/$today-robots-http.txt"
  printf -- '- Trust HTTP: `%s`, `%s`\n' "$evidence_dir/$today-about-http.txt" "$evidence_dir/$today-privacy-http.txt"
  printf '\nNo repo mutation is performed by this audit. Create an ULW plan before any bounded repair.\n'
} >"$evidence_dir/$today-summary.md"

if [ "${YOLKMEET_DAILY_OPS_SKIP_HTTP:-0}" = "1" ]; then
  printf 'HTTP checks skipped by YOLKMEET_DAILY_OPS_SKIP_HTTP=1\n'
fi
printf 'daily ops audit evidence: %s\n' "$evidence_dir/$today-summary.md"
