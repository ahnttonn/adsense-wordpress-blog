#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
configure_script="$repo_root/infra/configure-adsense-approval-package.sh"
preflight_script="$repo_root/infra/adsense-preflight.sh"
audit_script="$repo_root/infra/audit-adsense-readiness.sh"
checklist_doc="$repo_root/docs/adsense-approval-package.md"
theme_functions="$repo_root/wordpress/themes/yolkmeet-editorial/functions.php"
theme_styles="$repo_root/wordpress/themes/yolkmeet-editorial/style.css"
fixture_dir="$repo_root/tests/fixtures/adsense-policy"
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
    fail "missing AdSense package evidence: $description"
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local description="$3"
  if printf '%s' "$haystack" | grep -Fq -- "$needle"; then
    fail "unexpected AdSense package evidence: $description"
  fi
}

assert_file "$configure_script" "AdSense approval package configurator"
assert_file "$preflight_script" "AdSense preflight auditor"
assert_file "$audit_script" "AdSense readiness auditor"
assert_file "$checklist_doc" "AdSense approval package checklist"
assert_file "$fixture_dir/good/editorial-policy.html" "good editorial policy fixture"
assert_file "$fixture_dir/placeholder/editorial-policy.html" "placeholder editorial policy fixture"
assert_file "$fixture_dir/prompt-injection/editorial-policy.html" "prompt-injection editorial policy fixture"

if [ -f "$configure_script" ]; then
  bash -n "$configure_script" || fail "configurator syntax failed"
  body="$(sed -n '1,320p' "$configure_script")"
  for slug in about contact privacy-policy terms editorial-policy ai-use-policy affiliate-disclosure cookie-policy; do
    assert_contains "$body" "\"$slug\"" "configurator publishes $slug"
  done
  for slug in ai-tool-comparisons ai-workflow-automation ai-research-playbooks ai-marketing-ops ai-prompt-systems; do
    assert_contains "$body" "$slug" "configurator keeps $slug in the Topics menu"
  done
  for label in "Tool Comparisons" "Workflow Automation" "Research Playbooks" "Marketing Ops" "Prompt Systems"; do
    assert_contains "$body" "$label" "configurator uses broadened topic label: $label"
  done
  assert_contains "$body" "term update category" "configurator applies category descriptions"
  assert_contains "$body" "--description" "configurator writes category archive descriptions"
  assert_contains "$body" "ensure_page" "configurator uses idempotent page creation"
  assert_contains "$body" "menu item add-post" "configurator links trust pages through WordPress menus"
  assert_contains "$body" "AdSense application is account-gated" "configurator records account-gated submission boundary"
  assert_contains "$body" "--format=ids" "configurator uses host-supported WP-CLI id lookups"
  assert_not_contains "$body" "<ins class=\"adsbygoogle\"" "configurator must not add live ad units before approval"
  assert_not_contains "$body" "--field=ID" "configurator must not use unsupported wp post list --field lookup"
  assert_not_contains "$body" "--field=term_id" "configurator must not use unsupported wp term list --field lookup"
  assert_not_contains "$body" "menu list --field=slug" "configurator must not use unsupported wp menu list --field lookup"
fi

if [ -f "$preflight_script" ]; then
  bash -n "$preflight_script" || fail "preflight syntax failed"
  body="$(sed -n '1,320p' "$preflight_script")"
  assert_contains "$body" "privacy-policy" "preflight checks privacy policy"
  assert_contains "$body" "editorial-policy" "preflight checks editorial policy"
  assert_contains "$body" "affiliate-disclosure" "preflight checks affiliate disclosure"
  assert_contains "$body" "<ins class=\"adsbygoogle\"" "preflight blocks live ad units"
  assert_contains "$body" "click the ads" "preflight blocks click-inducing language"
  assert_contains "$body" "post_status=publish --format=count" "preflight checks content minimum"
  assert_contains "$body" "curl -fsSL" "preflight performs HTTP body checks"
  assert_contains "$body" "curl -I -L --max-time" "preflight performs bounded broken-link checks"
  assert_contains "$body" "POLICY_FIXTURE_DIR" "preflight can validate local policy fixtures"
  assert_contains "$body" "return 0" "preflight continues live checks when no policy fixture directory is set"
  assert_contains "$body" "restricted content scan" "preflight checks restricted content terms"
  assert_contains "$body" "deceptive ad placeholder language" "preflight blocks deceptive ad placeholders"
  assert_contains "$body" "ads.txt readiness boundary" "preflight checks ads.txt readiness boundary"
  assert_contains "$body" "user-owned AdSense submission checkpoint" "preflight records user-owned submission checkpoint"
  assert_contains "$body" "live sitemap timestamp captured" "preflight captures live freshness evidence"
  assert_contains "$body" "validate_base_url" "preflight rejects malformed site URLs"
fi

if [ -f "$audit_script" ]; then
  bash -n "$audit_script" || fail "readiness audit syntax failed"
  body="$(sed -n '1,360p' "$audit_script")"
  assert_contains "$body" "privacy-policy" "readiness audit checks privacy policy"
  assert_contains "$body" "editorial-policy" "readiness audit checks editorial policy"
  assert_contains "$body" "affiliate-disclosure" "readiness audit checks affiliate disclosure"
  assert_contains "$body" "broken-link audit checked" "readiness audit checks internal links"
  assert_contains "$body" "restricted content scan" "readiness audit checks restricted content terms"
  assert_contains "$body" "click-inducing ad language" "readiness audit blocks click-inducing language"
  assert_contains "$body" "reserved ad placeholder markup" "readiness audit flags reserved ad placeholders"
  assert_contains "$body" "ads.txt readiness boundary" "readiness audit checks ads.txt readiness boundary"
  assert_contains "$body" "user-owned AdSense submission checkpoint" "readiness audit records user-owned submission checkpoint"
  assert_contains "$body" "live sitemap timestamp captured" "readiness audit captures live freshness evidence"
  assert_contains "$body" "validate_site_url" "readiness audit rejects malformed site URLs"
fi

if [ -f "$checklist_doc" ]; then
  body="$(sed -n '1,260p' "$checklist_doc")"
  assert_contains "$body" "https://support.google.com/adsense/answer/9724" "eligibility source"
  assert_contains "$body" "https://support.google.com/adsense/answer/48182" "program policy source"
  assert_contains "$body" "https://support.google.com/adsense/answer/1346295" "placement policy source"
  assert_contains "$body" "User-owned account action" "application remains user-gated"
  assert_contains "$body" "No live ad units before approval" "no live ad rollout before approval"
fi

if [ -f "$theme_functions" ]; then
  body="$(cat "$theme_functions")"
  assert_contains "$body" "wp_head" "theme keeps AdSense verification in the document head"
  assert_contains "$body" "pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-1424742974208042" "theme keeps AdSense Auto ads head script"
  assert_not_contains "$body" "<ins class=\"adsbygoogle\"" "theme must not render live ad units before approval"
  assert_not_contains "$body" "adsbygoogle.push" "theme must not render manual AdSense push calls"
  assert_not_contains "$body" "data-ad-slot" "theme must not render manual ad unit slot ids"
  assert_not_contains "$body" "yolkmeet_editorial_render_ad_slot" "theme must not expose manual ad placeholder helper"
  assert_not_contains "$body" "Advertisement" "theme must not render visible ad placeholder copy"
  assert_not_contains "$body" "click the ads" "theme must not render click-inducing ad language"
  assert_not_contains "$body" "support us" "theme must not render click-inducing support language"
  assert_not_contains "$body" "Favorite Sites" "theme must not render misleading ad headings"
  assert_not_contains "$body" "Today's Top Offers" "theme must not render misleading ad headings"
fi

if [ -f "$theme_styles" ]; then
  body="$(cat "$theme_styles")"
  assert_not_contains "$body" ".ad-slot" "theme must not reserve visible manual ad slot boxes"
  assert_not_contains "$body" "min-height: 280px" "theme must not reserve mobile-safe manual ad slot height"
fi

if [ -x "$preflight_script" ] && [ -d "$fixture_dir" ]; then
  if POLICY_FIXTURE_DIR="$fixture_dir/good" "$preflight_script" >/dev/null 2>&1; then
    :
  else
    fail "preflight rejected good policy fixture"
  fi

  if POLICY_FIXTURE_DIR="$fixture_dir/placeholder" "$preflight_script" >/dev/null 2>&1; then
    fail "preflight allowed placeholder policy fixture"
  fi

  if POLICY_FIXTURE_DIR="$fixture_dir/prompt-injection" "$preflight_script" >/dev/null 2>&1; then
    fail "preflight allowed prompt-injection policy fixture"
  fi

  if "$preflight_script" not-a-url >/dev/null 2>&1; then
    fail "preflight allowed malformed site URL"
  fi
fi

if [ -x "$audit_script" ]; then
  if "$audit_script" not-a-url >/dev/null 2>&1; then
    fail "readiness audit allowed malformed site URL"
  fi
fi

if [ "$failures" -ne 0 ]; then
  echo "AdSense approval package checks failed: $failures" >&2
  exit 1
fi

echo "AdSense approval package checks passed: trust pages, preflight, checklist, and no live ad units"
