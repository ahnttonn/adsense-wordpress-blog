#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
configure_script="$repo_root/infra/configure-analytics-reporting.sh"
reporting_doc="$repo_root/docs/analytics-search-reporting.md"
weekly_template="$repo_root/docs/weekly-report-template.md"
theme_functions="$repo_root/wordpress/themes/yolkmeet-editorial/functions.php"
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
    fail "missing analytics package evidence: $description"
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local description="$3"
  if printf '%s' "$haystack" | grep -Fq -- "$needle"; then
    fail "unexpected analytics package evidence: $description"
  fi
}

assert_file "$configure_script" "analytics/reporting configurator"
assert_file "$reporting_doc" "analytics/reporting doc"
assert_file "$weekly_template" "weekly report template"

if [ -f "$configure_script" ]; then
  bash -n "$configure_script" || fail "analytics configurator syntax failed"
  body="$(sed -n '1,320p' "$configure_script")"
  assert_contains "$body" "GA4_MEASUREMENT_ID" "configurator accepts GA4 measurement ID"
  assert_contains "$body" "Search Console" "configurator documents Search Console checkpoint"
  assert_contains "$body" "Bing Webmaster Tools" "configurator documents Bing checkpoint"
  assert_contains "$body" "Weekly Reporting Template" "configurator writes weekly reporting template"
  assert_contains "$body" "PageSpeed" "configurator references PageSpeed monitoring"
  assert_contains "$body" "uptime" "configurator references uptime monitoring"
  assert_contains "$body" "invalid traffic" "configurator references invalid traffic checks"
fi

if [ -f "$reporting_doc" ]; then
  body="$(sed -n '1,320p' "$reporting_doc")"
  assert_contains "$body" "Search Console" "reporting doc covers Search Console"
  assert_contains "$body" "Bing Webmaster Tools" "reporting doc covers Bing"
  assert_contains "$body" "Weekly Report Template" "reporting doc includes weekly report template"
  assert_contains "$body" "organic traffic" "reporting doc tracks organic traffic"
  assert_contains "$body" "indexed pages" "reporting doc tracks indexation"
  assert_contains "$body" "top queries" "reporting doc tracks query performance"
  assert_contains "$body" "Core Web Vitals" "reporting doc tracks Core Web Vitals"
  assert_contains "$body" "AdSense readiness" "reporting doc tracks AdSense readiness"
  assert_contains "$body" "invalid traffic review" "reporting doc tracks invalid traffic"
fi

if [ -f "$theme_functions" ]; then
  body="$(sed -n '1,320p' "$theme_functions")"
  assert_contains "$body" "yolkmeet_editorial_analytics" "theme exposes an opt-in analytics hook"
  assert_contains "$body" "YOLKMEET_GA4_MEASUREMENT_ID" "theme keeps GA4 opt-in"
  assert_contains "$body" "get_option('_yolkmeet_ga4_measurement_id'" "theme supports stored measurement ID"
fi

if [ "$failures" -ne 0 ]; then
  echo "analytics/reporting package checks failed: $failures" >&2
  exit 1
fi

echo "analytics/reporting package checks passed: configurator, reporting doc, and opt-in analytics hook"
