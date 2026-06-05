#!/usr/bin/env bash
set -euo pipefail

SITE_URL="${1:-${SITE_URL:-https://www.yolkmeet.com}}"
SITE_URL="${SITE_URL%/}"
MAX_TIME="${MAX_TIME:-15}"
TMP_DIR="$(mktemp -d)"
failures=0
warnings=0

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

warn() {
  printf 'WARN: %s\n' "$1" >&2
  warnings=$((warnings + 1))
}

pass() {
  printf 'PASS: %s\n' "$1"
}

validate_site_url() {
  case "$SITE_URL" in
    http://*|https://*) ;;
    *)
      printf 'FAIL: site URL must start with http:// or https://: %s\n' "$SITE_URL" >&2
      exit 2
      ;;
  esac

  if printf '%s' "$SITE_URL" | grep -Eq '[[:space:]<>"]'; then
    printf 'FAIL: site URL contains unsafe characters: %s\n' "$SITE_URL" >&2
    exit 2
  fi
}

fetch_url() {
  local url="$1"
  local output="$2"
  curl -i -L --max-time "$MAX_TIME" "$url" >"$output"
}

check_page() {
  local slug="$1"
  local expected="$2"
  local url="$SITE_URL/$slug/"
  local output="$TMP_DIR/$slug.http"

  if ! fetch_url "$url" "$output"; then
    fail "$url did not respond"
    return
  fi

  if grep -Eq 'HTTP/[0-9.]+ 200' "$output"; then
    pass "$url returned HTTP 200"
  else
    fail "$url did not return HTTP 200"
  fi

  if grep -Fq "$expected" "$output"; then
    pass "$url contains expected page marker"
  else
    fail "$url is missing expected marker: $expected"
  fi

  if grep -Eiq 'placeholder|Lorem ipsum|TODO|sample page' "$output"; then
    fail "$url contains placeholder copy"
  fi
}

check_navigation() {
  local homepage="$TMP_DIR/homepage.http"
  local slug
  local slugs=("about" "contact" "privacy-policy" "terms" "editorial-policy" "ai-use-policy" "affiliate-disclosure" "cookie-policy")

  if ! fetch_url "$SITE_URL/" "$homepage"; then
    fail "$SITE_URL/ did not respond"
    return
  fi

  for slug in "${slugs[@]}"; do
    if grep -Eq "href=[\"'][^\"']*/$slug/?[\"']" "$homepage"; then
      pass "homepage links /$slug/"
    else
      fail "homepage is missing /$slug/ link"
    fi
  done

  if grep -Eiq 'click the ads|support us|visit these links|Favorite Sites|Today'\''s Top Offers' "$homepage"; then
    fail "homepage contains click-inducing ad language"
  else
    pass "homepage has no click-inducing ad language"
  fi

  if grep -Fq 'Advertisement reserved' "$homepage"; then
    pass "homepage uses neutral Advertisement reserved placeholder label"
  fi

  if grep -Eiq 'Advertisement placeholder|ad slot|ad placeholder' "$homepage"; then
    warn "homepage contains reserved ad placeholder markup that should stay non-live until approval"
  else
    pass "homepage has no reserved ad placeholder markup"
  fi

  if grep -Eiq 'Favorite Sites|Today'\''s Top Offers|sponsored link placeholder|TODO ad|coming soon ad' "$homepage"; then
    fail "homepage contains deceptive ad placeholder language"
  else
    pass "homepage has no deceptive ad placeholder language"
  fi

  if grep -Eiq '<ins class=["'\'']adsbygoogle["'\'']|data-ad-slot|adsbygoogle\.push' "$homepage"; then
    fail "homepage contains live ad unit markup before approval"
  else
    pass "homepage has no live ad unit markup"
  fi
}

check_broken_links() {
  local homepage="$TMP_DIR/homepage-links.http"
  local links="$TMP_DIR/links.txt"
  local link status
  local checked=0

  if ! fetch_url "$SITE_URL/" "$homepage"; then
    fail "could not fetch homepage for broken-link audit"
    return
  fi

  {
    grep -Eo 'href="[^"]+"' "$homepage" \
    | sed -E 's/^href="|"$//g' \
    | awk -v base="$SITE_URL" '$0 ~ /^\// || index($0, base "/") == 1 { print }' \
    | sed -E "s#^/#$SITE_URL/#" \
    | sort -u
  } >"$links" || true

  while IFS= read -r link; do
    [ -n "$link" ] || continue
    status="$(curl -I -L --max-time "$MAX_TIME" -o /dev/null -s -w '%{http_code}' "$link" || true)"
    checked=$((checked + 1))
    case "$status" in
      200|301|302|304) ;;
      *) fail "broken internal link candidate: $status $link" ;;
    esac
  done < "$links"

  if [ "$checked" -eq 0 ]; then
    warn "broken-link audit found no internal homepage links to check"
  else
    pass "broken-link audit checked $checked internal homepage links"
  fi
}

check_content_minimum() {
  local sitemap="$TMP_DIR/sitemap.xml"
  local post_count

  if curl -s --max-time "$MAX_TIME" "$SITE_URL/sitemap.xml" >"$sitemap"; then
    post_count="$(grep -Eo "$SITE_URL/[^<]+/" "$sitemap" | grep -Ev '/(about|contact|privacy-policy|terms|editorial-policy|ai-use-policy|affiliate-disclosure|cookie-policy|category)/$' | wc -l | tr -d ' ')"
    if [ "$post_count" -ge 30 ]; then
      pass "sitemap has at least 30 content URLs"
    else
      fail "sitemap content URL count is below 30: $post_count"
    fi
  else
    fail "sitemap fetch failed"
  fi
}

check_restricted_content() {
  local combined="$TMP_DIR/restricted-scan.txt"
  local homepage="$TMP_DIR/homepage-restricted.http"
  local sitemap="$TMP_DIR/sitemap-restricted.xml"

  : >"$combined"
  if fetch_url "$SITE_URL/" "$homepage"; then
    cat "$homepage" >>"$combined"
  else
    fail "homepage fetch failed for restricted-content scan"
    return
  fi

  if curl -fsSL --max-time "$MAX_TIME" "$SITE_URL/sitemap.xml" >"$sitemap"; then
    cat "$sitemap" >>"$combined"
  else
    warn "sitemap fetch failed for restricted-content scan"
  fi

  if grep -Eiq 'adult content|porn|casino|gambling|illegal drugs|weapon sales|malware|phishing kit|fake passport|counterfeit goods|payday loan|get rich quick' "$combined"; then
    fail "restricted content scan found high-risk policy phrases"
  else
    pass "restricted content scan found no high-risk policy phrases"
  fi
}

check_ads_txt_boundary() {
  local ads_txt="$TMP_DIR/ads.txt"
  local status

  status="$(curl -L --max-time "$MAX_TIME" -o "$ads_txt" -s -w '%{http_code}' "$SITE_URL/ads.txt" || true)"
  case "$status" in
    200)
      if grep -Eq '^google\.com,[[:space:]]*pub-[0-9]+,[[:space:]]*DIRECT' "$ads_txt"; then
        pass "ads.txt readiness boundary has a Google direct publisher entry"
      else
        warn "ads.txt exists but no Google direct publisher entry was found; confirm after AdSense account setup"
      fi
      ;;
    404)
      pass "ads.txt readiness boundary checked: ads.txt can wait for user-owned account setup"
      ;;
    *)
      warn "ads.txt readiness boundary returned HTTP $status"
      ;;
  esac
}

check_user_owned_submission() {
  pass "user-owned AdSense submission checkpoint remains outside automation"
}

capture_live_timestamp() {
  local headers="$TMP_DIR/sitemap.headers"
  local marker

  if curl -I --max-time "$MAX_TIME" "$SITE_URL/sitemap.xml" >"$headers" 2>/dev/null; then
    marker="$(grep -Ei '^Last-Modified:|^Date:' "$headers" | paste -sd ' ' -)"
    pass "live sitemap timestamp captured: ${marker:-header fetched without Date/Last-Modified}"
  else
    warn "live sitemap timestamp capture failed"
  fi
}

main() {
  validate_site_url
  check_page "about" "Yolkmeet publishes"
  check_page "contact" "editor@yolkmeet.com"
  check_page "privacy-policy" "Privacy Policy"
  check_page "terms" "Terms of Use"
  check_page "editorial-policy" "Editorial Policy"
  check_page "ai-use-policy" "AI Use Policy"
  check_page "affiliate-disclosure" "Affiliate Disclosure"
  check_page "cookie-policy" "Cookie Policy"
  check_navigation
  check_broken_links
  check_content_minimum
  check_restricted_content
  check_ads_txt_boundary
  check_user_owned_submission
  capture_live_timestamp

  printf 'AdSense readiness audit complete: PASS|WARN|FAIL summary failures=%d warnings=%d\n' "$failures" "$warnings"
  if [ "$failures" -ne 0 ]; then
    exit 1
  fi
}

main "$@"
