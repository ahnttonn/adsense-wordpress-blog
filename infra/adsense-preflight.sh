#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-${SITE_URL:-${BASE_URL:-https://www.yolkmeet.com}}}"
BASE_URL="${BASE_URL%/}"
WP_ROOT="${WP_ROOT:-/var/www/yolkmeet.com}"
WP_USER="${WP_USER:-wpdeploy}"
MIN_POSTS="${MIN_POSTS:-30}"
MAX_TIME="${MAX_TIME:-15}"
POLICY_FIXTURE_DIR="${POLICY_FIXTURE_DIR:-}"
TMP_DIR="$(mktemp -d)"
failures=0
warnings=0

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

wp_cli() {
  if command -v wp >/dev/null 2>&1 && [ -d "$WP_ROOT" ]; then
    if command -v sudo >/dev/null 2>&1 && id "$WP_USER" >/dev/null 2>&1 && [ "$(id -un)" != "$WP_USER" ]; then
      sudo -u "$WP_USER" wp --path="$WP_ROOT" "$@"
    else
      wp --path="$WP_ROOT" "$@"
    fi
  else
    return 127
  fi
}

pass() {
  printf 'PASS %s\n' "$*"
}

warn() {
  printf 'WARN %s\n' "$*"
  warnings=$((warnings + 1))
}

fail() {
  printf 'FAIL %s\n' "$*" >&2
  failures=$((failures + 1))
}

validate_base_url() {
  case "$BASE_URL" in
    http://*|https://*) ;;
    *)
      printf 'FAIL site URL must start with http:// or https://: %s\n' "$BASE_URL" >&2
      exit 2
      ;;
  esac

  if printf '%s' "$BASE_URL" | grep -Eq '[[:space:]<>"]'; then
    printf 'FAIL site URL contains unsafe characters: %s\n' "$BASE_URL" >&2
    exit 2
  fi
}

fetch_body() {
  local slug="$1"
  local url="$BASE_URL/$slug/"
  local body
  if ! body="$(curl -fsSL --max-time "$MAX_TIME" "$url")"; then
    fail "$slug did not return a successful body"
    return 1
  fi
  printf '%s' "$body"
}

check_policy_fixture_dir() {
  local fixture_file="$POLICY_FIXTURE_DIR/editorial-policy.html"
  local body

  if [ "$POLICY_FIXTURE_DIR" = "" ]; then
    return 0
  fi

  if [ ! -f "$fixture_file" ]; then
    fail "policy fixture missing: $fixture_file"
  else
    body="$(cat "$fixture_file")"
    if printf '%s' "$body" | grep -Eiq 'placeholder|coming soon|Lorem ipsum|TODO|sample page'; then
      fail "policy fixture contains placeholder copy"
    else
      pass "policy fixture has no placeholder copy"
    fi
    if printf '%s' "$body" | grep -Eiq 'ignore previous|ignore .*policy checks|mark this page approved|skip source attribution'; then
      fail "policy fixture contains prompt-injection language"
    else
      pass "policy fixture has no prompt-injection language"
    fi
    if printf '%s' "$body" | grep -Eiq 'Yolkmeet|editor@yolkmeet\.com|source URLs|corrections|review'; then
      pass "policy fixture has site-specific policy content"
    else
      fail "policy fixture lacks site-specific policy content"
    fi
  fi

  if [ "$failures" -ne 0 ]; then
    printf 'FAILURES %s\n' "$failures" >&2
    exit 1
  fi
  printf 'PASS AdSense policy fixture checks passed\n'
  exit 0
}

check_trust_page() {
  local slug="$1"
  local body
  body="$(fetch_body "$slug")" || return
  if printf '%s' "$body" | grep -Eiq 'placeholder|Lorem ipsum|TODO|sample page'; then
    fail "$slug contains placeholder copy"
  else
    pass "$slug has no placeholder copy"
  fi
  if printf '%s' "$body" | grep -Eiq 'click the ads|support us|visit these links|Favorite Sites|Today'\''s Top Offers'; then
    fail "$slug contains click-inducing language"
  else
    pass "$slug has no click-inducing language"
  fi
  if printf '%s' "$body" | grep -Eiq 'Favorite Sites|Today'\''s Top Offers|resources[^<]{0,80}ads?|helpful links[^<]{0,80}ads?|sponsored link placeholder|TODO ad|coming soon ad'; then
    fail "$slug contains deceptive ad placeholder language"
  else
    pass "$slug has no deceptive ad placeholder language"
  fi
  if printf '%s' "$body" | grep -Eiq 'Yolkmeet|editor@yolkmeet\.com|source URLs|source notes|corrections|review|cookies|AdSense|affiliate'; then
    pass "$slug has site-specific policy content"
  else
    fail "$slug lacks site-specific policy content"
  fi
}

check_homepage_links_and_ads() {
  local body
  body="$(curl -fsSL --max-time "$MAX_TIME" "$BASE_URL/")" || {
    fail "homepage body fetch failed"
    return
  }
  for label in About Contact "Privacy Policy" "Terms of Use" "Editorial Policy" "AI Use Policy" "Affiliate Disclosure" "Cookie Policy"; do
    if printf '%s' "$body" | grep -Fq ">$label<"; then
      pass "homepage links $label"
    else
      fail "homepage missing $label"
    fi
  done
  if printf '%s' "$body" | grep -Eq '>Terms( of Use)?(<|</a>)'; then
    pass "homepage links Terms"
  else
    fail "homepage missing Terms"
  fi
  if printf '%s' "$body" | grep -Fq '<ins class="adsbygoogle"' || printf '%s' "$body" | grep -Eiq 'data-ad-slot|adsbygoogle\.push'; then
    fail "homepage contains live ad units before approval"
  else
    pass "No live ad units before approval"
  fi
  if printf '%s' "$body" | grep -Eiq 'click the ads|support us|visit these links|Favorite Sites|Today'\''s Top Offers'; then
    fail "homepage contains click-inducing language"
  else
    pass "homepage has no click-inducing language"
  fi
  if printf '%s' "$body" | grep -Eiq 'Favorite Sites|Today'\''s Top Offers|resources[^<]{0,80}ads?|helpful links[^<]{0,80}ads?|sponsored link placeholder|TODO ad|coming soon ad'; then
    fail "homepage contains deceptive ad placeholder language"
  else
    pass "homepage has no deceptive ad placeholder language"
  fi
}

check_content_minimum() {
  local count
  if count="$(wp_cli post list --post_type=post --post_status=publish --format=count 2>/dev/null)"; then
    if [ "$count" -ge "$MIN_POSTS" ]; then
      pass "published post count is $count"
    else
      fail "published post count is below $MIN_POSTS: $count"
    fi
    return
  fi
  local sitemap_count
  sitemap_count="$(curl -fsSL --max-time "$MAX_TIME" "$BASE_URL/sitemap.xml" | grep -Eoc "$BASE_URL/.+/.+/" || true)"
  if [ "$sitemap_count" -ge "$MIN_POSTS" ]; then
    pass "sitemap content count is $sitemap_count"
  else
    fail "sitemap content count is below $MIN_POSTS: $sitemap_count"
  fi
}

check_broken_links() {
  local homepage="$TMP_DIR/homepage-links.html"
  local links="$TMP_DIR/links.txt"
  local checked=0
  local link status

  if ! curl -fsSL --max-time "$MAX_TIME" "$BASE_URL/" >"$homepage"; then
    fail "homepage fetch failed for broken-link audit"
    return
  fi

  {
    grep -Eo 'href="[^"]+"' "$homepage" \
      | sed -E 's/^href="|"$//g' \
      | awk -v base="$BASE_URL" '$0 ~ /^\// || index($0, base "/") == 1 { print }' \
      | sed -E "s#^/#$BASE_URL/#" \
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
  done <"$links"

  if [ "$checked" -eq 0 ]; then
    warn "broken-link audit found no internal homepage links to check"
  else
    pass "broken-link audit checked $checked internal homepage links"
  fi
}

check_restricted_content() {
  local combined="$TMP_DIR/restricted-scan.txt"
  local sitemap="$TMP_DIR/sitemap-restricted.xml"

  : >"$combined"
  curl -fsSL --max-time "$MAX_TIME" "$BASE_URL/" >>"$combined" || {
    fail "homepage fetch failed for restricted-content scan"
    return
  }
  curl -fsSL --max-time "$MAX_TIME" "$BASE_URL/sitemap.xml" >"$sitemap" && cat "$sitemap" >>"$combined" || warn "sitemap fetch failed for restricted-content scan"

  if grep -Eiq 'adult content|porn|casino|gambling|illegal drugs|weapon sales|malware|phishing kit|fake passport|counterfeit goods|payday loan|get rich quick' "$combined"; then
    fail "restricted content scan found high-risk policy phrases"
  else
    pass "restricted content scan found no high-risk policy phrases"
  fi
}

check_ads_txt_boundary() {
  local ads_txt="$TMP_DIR/ads.txt"
  local status

  status="$(curl -L --max-time "$MAX_TIME" -o "$ads_txt" -s -w '%{http_code}' "$BASE_URL/ads.txt" || true)"
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

capture_live_timestamp() {
  local headers="$TMP_DIR/sitemap.headers"
  local marker

  if curl -I --max-time "$MAX_TIME" "$BASE_URL/sitemap.xml" >"$headers" 2>/dev/null; then
    marker="$(grep -Ei '^Last-Modified:|^Date:' "$headers" | paste -sd ' ' -)"
    pass "live sitemap timestamp captured: ${marker:-header fetched without Date/Last-Modified}"
  else
    warn "live sitemap timestamp capture failed"
  fi
}

check_user_owned_submission() {
  pass "user-owned AdSense submission checkpoint remains outside automation"
}

check_malformed_search() {
  local body
  body="$(curl -fsSL --max-time "$MAX_TIME" "$BASE_URL/?s=%3Cscript%3Eadsense%3C%2Fscript%3E")" || {
    warn "malformed search body fetch failed"
    return
  }
  if printf '%s' "$body" | grep -Fq '<script>adsense</script>'; then
    fail "malformed search rendered raw script"
  else
    pass "malformed search escaped raw script"
  fi
}

validate_base_url
check_policy_fixture_dir

for slug in about contact privacy-policy terms editorial-policy ai-use-policy affiliate-disclosure cookie-policy; do
  check_trust_page "$slug"
done
check_homepage_links_and_ads
check_content_minimum
check_broken_links
check_restricted_content
check_ads_txt_boundary
check_user_owned_submission
capture_live_timestamp
check_malformed_search

if [ "$warnings" -gt 0 ]; then
  printf 'WARNINGS %s\n' "$warnings"
fi

if [ "$failures" -ne 0 ]; then
  printf 'FAILURES %s\n' "$failures" >&2
  exit 1
fi

printf 'PASS AdSense preflight critical checks passed\n'
