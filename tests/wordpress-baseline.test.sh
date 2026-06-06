#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo_root/infra/configure-wordpress-baseline.sh"
failures=0

fail() {
  echo "$1" >&2
  failures=$((failures + 1))
}

require_pattern() {
  local pattern="$1"
  local description="$2"
  if [ ! -f "$script" ]; then
    fail "missing baseline script: $script"
    return
  fi
  if ! grep -Eq -- "$pattern" "$script"; then
    fail "missing baseline policy: $description"
  fi
}

require_valid_slug_value() {
  local variable_name="$1"
  local value
  value="$(awk -F= -v name="$variable_name" '$1 == name {gsub(/"/, "", $2); print $2; exit}' "$script")"
  if [ -z "$value" ]; then
    fail "missing slug variable: $variable_name"
    return
  fi
  if ! printf '%s\n' "$value" | grep -Eq '^[a-z0-9][a-z0-9-]*$'; then
    fail "invalid WordPress slug in $variable_name: $value"
  fi
}

forbid_pattern() {
  local pattern="$1"
  local description="$2"
  if [ ! -f "$script" ]; then
    return
  fi
  if grep -Eiq -- "$pattern" "$script"; then
    fail "forbidden baseline policy: $description"
  fi
}

if [ ! -f "$script" ]; then
  fail "missing baseline script: $script"
else
  if [ ! -x "$script" ]; then
    fail "baseline script is not executable: $script"
  fi
  bash -n "$script" || fail "baseline script syntax failed"
fi

require_valid_slug_value THEME_SLUG
require_valid_slug_value SEO_PLUGIN

require_pattern 'THEME_SLUG="yolkmeet-editorial"' "activates the custom editorial theme"
require_pattern 'SEO_PLUGIN="autodescription"' "uses exactly one lightweight SEO/schema plugin"
require_pattern 'redis-cache' "keeps Redis object cache"
require_pattern 'plugin install "\$SEO_PLUGIN"' "installs SEO plugin through WP-CLI"
require_pattern 'plugin activate "\$SEO_PLUGIN"' "activates SEO plugin"
require_pattern 'plugin install "\$SECURITY_PLUGIN"' "installs one lightweight security plugin"
require_pattern 'plugin activate "\$SECURITY_PLUGIN"' "activates one lightweight security plugin"
require_pattern 'theme activate "\$THEME_SLUG"' "activates custom theme"
require_pattern 'option update permalink_structure' "sets clean permalink structure without Apache hard flush"
require_pattern 'About|Contact|Privacy' "creates required trust pages"
require_pattern 'post create' "creates a real sample post for theme QA"
require_pattern 'term create category' "creates a category surface"
require_pattern 'term list category --slug=ai-workflow-automation' "looks up category by slug or id"
for slug in ai-tool-comparisons ai-workflow-automation ai-research-playbooks ai-marketing-ops ai-prompt-systems; do
  require_pattern "$slug" "keeps $slug category available"
done
for label in "Tool Comparisons" "Workflow Automation" "Research Playbooks" "Marketing Ops" "Prompt Systems"; do
  require_pattern "$label" "uses broadened visible topic label: $label"
done
require_pattern 'term update category|--description' "updates category descriptions for archive pages"
require_pattern 'option update blog_public 1' "allows AdSense and Google crawlers to verify the public site"
require_pattern 'option update blogname "YOLKMEET"' "sets public brand casing"
require_pattern 'option update blogdescription "Operator-tech field guides, automation playbooks, and workflow comparisons"' "sets broadened operator-tech tagline"
require_pattern 'elementor|divi|beaver-builder|visual-composer' "guards against heavy builders"
require_pattern 'delete_managed_menus' "clears managed menus before re-adding them"
require_pattern 'for menu_slug in primary topics footer' "uses stable menu slugs for idempotent reruns"
require_pattern 'menu list --field=slug' "checks existing managed menus by slug"
require_pattern 'grep -Fxq "\$menu_slug"' "matches managed menu slugs exactly"
require_pattern 'menu delete "\$menu_slug"' "deletes stale managed menus by slug for idempotent reruns"
require_pattern 'menu create Primary' "recreates the primary menu from a clean state"
forbid_pattern 'wp plugin install .*(rank-math|wordpress-seo|aioseo|seopress)' "must not install overlapping SEO plugin families"
forbid_pattern 'wp plugin install .*(elementor|divi|beaver-builder|visual-composer)' "must not install heavy builders"
forbid_pattern 'ca-pub-|pagead2\.googlesyndication\.com|adsbygoogle' "must not install live AdSense code before approval rollout"
forbid_pattern 'rewrite (structure|flush)' "must not call WP-CLI rewrite commands on Nginx host"
forbid_pattern 'menu item delete' "must not rely on flaky item-level menu deletion"
forbid_pattern 'menu list --fields=term_id,name --format=csv' "must not parse menu CSV for managed menu cleanup"
forbid_pattern 'menu item list .*--field=ID' "must not use unsupported WP-CLI menu item --field flag"
forbid_pattern '--by=name' "must not use unsupported WP-CLI term lookup mode"

if [ "$failures" -ne 0 ]; then
  echo "wordpress baseline checks failed: $failures" >&2
  exit 1
fi

echo "desired WordPress baseline checks passed: custom theme, single SEO plugin, Redis retention, trust pages, sample content, clean permalinks"
