#!/usr/bin/env bash
set -euo pipefail

WP_ROOT="${WP_ROOT:-/var/www/yolkmeet.com}"
WP_USER="${WP_USER:-wpdeploy}"
GA4_MEASUREMENT_ID="${GA4_MEASUREMENT_ID:-}"
REPORT_DOC="${REPORT_DOC:-$PWD/docs/analytics-search-reporting.md}"
WEEKLY_TEMPLATE="${WEEKLY_TEMPLATE:-$PWD/docs/weekly-report-template.md}"

wp_cli() {
  if command -v sudo >/dev/null 2>&1 && id "$WP_USER" >/dev/null 2>&1 && [ "$(id -un)" != "$WP_USER" ]; then
    sudo -u "$WP_USER" wp --path="$WP_ROOT" "$@"
  else
    wp --path="$WP_ROOT" "$@"
  fi
}

write_weekly_template() {
  printf '%s\n' \
    '# Weekly Search and Revenue Readiness Report' \
    '' \
    '- UTC week ending:' \
    '- Live domain:' \
    '' \
    '## Traffic' \
    '- Organic traffic:' \
    '- Indexed pages:' \
    '- Top queries:' \
    '- CTR:' \
    '' \
    '## Content' \
    '- New articles published:' \
    '- Articles refreshed:' \
    '- Article decay watchlist:' \
    '- Internal links added:' \
    '' \
    '## Technical Health' \
    '- Core Web Vitals:' \
    '- PageSpeed mobile:' \
    '- PageSpeed desktop:' \
    '- Uptime:' \
    '- Log sanity review:' \
    '- Sitemap submission status:' \
    '' \
    '## Monetization Readiness' \
    '- AdSense readiness:' \
    '- Invalid traffic review:' \
    '- Consent/privacy follow-ups:' \
    '' \
    '## Notes' \
    '- Search Console checkpoint:' \
    '- Bing Webmaster Tools checkpoint:' \
    '- GA4 measurement ID:'
}

configure_ga4_option() {
  if [ "$GA4_MEASUREMENT_ID" = "" ]; then
    return
  fi

  wp_cli option update _yolkmeet_ga4_measurement_id "$GA4_MEASUREMENT_ID" >/dev/null
}

main() {
  configure_ga4_option
  mkdir -p "$(dirname "$REPORT_DOC")"
  write_weekly_template >"$REPORT_DOC"
  mkdir -p "$(dirname "$WEEKLY_TEMPLATE")"
  write_weekly_template >"$WEEKLY_TEMPLATE"
  printf 'Analytics/reporting configured: GA4=%s, reporting_template=%s\n' "${GA4_MEASUREMENT_ID:-<checkpoint-required>}" "$REPORT_DOC"
  printf 'Weekly Reporting Template covers organic traffic, indexed pages, top queries, Core Web Vitals, AdSense readiness, and invalid traffic review.\n'
  printf 'Account-gated checkpoints: Search Console verification, sitemap submission, and Bing Webmaster Tools submission remain user-owned unless credentials are available.\n'
  printf 'Monitoring: PageSpeed, uptime, log-based traffic sanity checks, and invalid traffic review should run on the weekly cadence.\n'
}

main "$@"
