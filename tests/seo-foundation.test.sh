#!/usr/bin/env bash
set -euo pipefail

base_url="https://www.yolkmeet.com"
home_url="$base_url/"
robots_url="$base_url/robots.txt"
sitemap_url="$base_url/sitemap.xml"
post_url="$base_url/ai-workflow-automation/ai-workflow-automation-stack-starter/"
wp_sitemap_url="$base_url/wp-sitemap.xml"
failures=0

fail() {
  echo "$1" >&2
  failures=$((failures + 1))
}

capture() {
  local __name="$1"
  local url="$2"
  local label="$3"
  local body=""

  if ! body="$(curl -fsSL --max-time 15 "$url")"; then
    fail "failed to fetch $label: $url"
  fi

  printf -v "$__name" '%s' "$body"
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local description="$3"

  if ! printf '%s' "$haystack" | grep -Fq -- "$needle"; then
    fail "missing SEO baseline evidence: $description"
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local description="$3"

  if printf '%s' "$haystack" | grep -Fq -- "$needle"; then
    fail "unexpected SEO baseline drift: $description"
  fi
}

assert_count() {
  local haystack="$1"
  local needle="$2"
  local expected="$3"
  local description="$4"
  local actual

  actual="$(printf '%s' "$haystack" | grep -Fc -- "$needle" || true)"
  if [ "$actual" != "$expected" ]; then
    fail "unexpected SEO baseline count for $description: expected $expected, got $actual"
  fi
}

home_html=""
robots_txt=""
sitemap_xml=""
post_html=""
wp_sitemap_status=""

capture home_html "$home_url" "homepage"
capture robots_txt "$robots_url" "robots.txt"
capture sitemap_xml "$sitemap_url" "sitemap.xml"
capture post_html "$post_url" "sample post"
wp_sitemap_status="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 15 "$wp_sitemap_url" || true)"

assert_contains "$robots_txt" "User-agent: *" "robots.txt user-agent rule"
assert_contains "$robots_txt" "Disallow: /wp-admin/" "robots.txt admin disallow"
assert_contains "$robots_txt" "Allow: /wp-admin/admin-ajax.php" "robots.txt admin-ajax allowance"
assert_contains "$robots_txt" "Sitemap: https://www.yolkmeet.com/sitemap.xml" "robots.txt sitemap pointer"

assert_contains "$sitemap_xml" "<?xml-stylesheet type=\"text/xsl\" href=\"https://www.yolkmeet.com/sitemap.xsl\"?>" "sitemap stylesheet link"
assert_count "$sitemap_xml" "<loc>" 5 "sitemap URL entries"
assert_contains "$sitemap_xml" "<loc>https://www.yolkmeet.com/</loc>" "homepage sitemap entry"
assert_contains "$sitemap_xml" "<lastmod>2026-06-05T08:46:57+00:00</lastmod>" "homepage sitemap last modified"
assert_contains "$sitemap_xml" "<loc>https://www.yolkmeet.com/privacy/</loc>" "privacy sitemap entry"
assert_contains "$sitemap_xml" "<lastmod>2026-06-05T09:00:33+00:00</lastmod>" "privacy/contact sitemap last modified"
assert_contains "$sitemap_xml" "<loc>https://www.yolkmeet.com/contact/</loc>" "contact sitemap entry"
assert_contains "$sitemap_xml" "<loc>https://www.yolkmeet.com/about/</loc>" "about sitemap entry"
assert_contains "$sitemap_xml" "<lastmod>2026-06-05T09:00:32+00:00</lastmod>" "about sitemap last modified"
assert_contains "$sitemap_xml" "<loc>https://www.yolkmeet.com/ai-workflow-automation/ai-workflow-automation-stack-starter/</loc>" "sample post sitemap entry"
assert_contains "$sitemap_xml" "<lastmod>2026-06-05T09:00:34+00:00</lastmod>" "sample post sitemap last modified"

if [ "$wp_sitemap_status" != "404" ]; then
  fail "unexpected wp-sitemap.xml status: expected 404, got $wp_sitemap_status"
fi

assert_contains "$home_html" "<title>Yolkmeet - AI automation field guides and workflow comparisons</title>" "homepage title"
assert_contains "$home_html" "<meta name=\"robots\" content=\"max-snippet:-1,max-image-preview:large,max-video-preview:-1\" />" "homepage robots meta"
assert_contains "$home_html" "<link rel=\"canonical\" href=\"https://www.yolkmeet.com/\" />" "homepage canonical URL"
assert_contains "$home_html" "\"@type\":\"WebSite\"" "homepage WebSite schema"
assert_contains "$home_html" "\"@type\":\"WebPage\"" "homepage WebPage schema"
assert_contains "$home_html" "\"@type\":\"Organization\"" "homepage Organization schema"
assert_contains "$home_html" "\"name\":\"Yolkmeet\",\"description\":\"AI automation field guides and workflow comparisons\"" "homepage schema brand description"
assert_contains "$home_html" "\"urlTemplate\":\"https://www.yolkmeet.com/search/{search_term_string}/\"" "homepage search action schema"

assert_contains "$post_html" "<title>AI Workflow Automation Stack: Starter Notes - Yolkmeet</title>" "post title"
assert_contains "$post_html" "<meta name=\"robots\" content=\"max-snippet:-1,max-image-preview:large,max-video-preview:-1\" />" "post robots meta"
assert_contains "$post_html" "<link rel=\"canonical\" href=\"https://www.yolkmeet.com/ai-workflow-automation/ai-workflow-automation-stack-starter/\" />" "post canonical URL"
assert_contains "$post_html" "<meta name=\"description\" content=\"A practical starter stack for AI workflow automation with review gates, comparison rules, and audit notes.\" />" "post meta description"
assert_contains "$post_html" "<meta property=\"article:published_time\" content=\"2026-06-05T08:46:57+00:00\" />" "post published time"
assert_contains "$post_html" "<meta property=\"article:modified_time\" content=\"2026-06-05T09:00:34+00:00\" />" "post modified time"
assert_contains "$post_html" "\"@type\":\"WebPage\"" "post WebPage schema"
assert_contains "$post_html" "\"breadcrumb\":{\"@type\":\"BreadcrumbList\"" "post breadcrumb schema"
assert_contains "$post_html" "\"datePublished\":\"2026-06-05T08:46:57+00:00\"" "post schema published date"
assert_contains "$post_html" "\"dateModified\":\"2026-06-05T09:00:34+00:00\"" "post schema modified date"
assert_contains "$post_html" "\"@type\":\"ReadAction\"" "post schema read action"
assert_contains "$post_html" "class=\"quick-answer\"" "post quick answer block"
assert_contains "$post_html" "section class=\"source-note\"" "post source note block"
assert_contains "$post_html" "section class=\"update-log\"" "post update log block"
assert_contains "$post_html" "nav class=\"breadcrumb\"" "post breadcrumb navigation"

assert_not_contains "$home_html" "wp-sitemap.xml" "homepage should not advertise wp-sitemap.xml"
assert_not_contains "$post_html" "wp-sitemap.xml" "post should not advertise wp-sitemap.xml"

if [ "$failures" -ne 0 ]; then
  echo "SEO baseline checks failed: $failures" >&2
  exit 1
fi

echo "SEO baseline checks passed: robots.txt, sitemap.xml, homepage meta/schema/canonical, and post meta/schema/canonical"
