#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo_root/infra/configure-wordpress-baseline.sh"
theme_slug="$(awk -F= '$1 == "THEME_SLUG" {gsub(/"/, "", $2); print $2; exit}' "$script")"
theme_dir="$repo_root/wordpress/themes/$theme_slug"
style_file="$theme_dir/style.css"
functions_file="$theme_dir/functions.php"
index_file="$theme_dir/index.php"
single_file="$theme_dir/single.php"
archive_file="$theme_dir/archive.php"
operator_theme_dir="$repo_root/wordpress/wp-content/themes/operator-editorial"
operator_style_file="$operator_theme_dir/style.css"
operator_index_file="$operator_theme_dir/index.php"
operator_author_box_file="$operator_theme_dir/template-parts/author-box.php"
operator_footer_file="$operator_theme_dir/footer.php"
failures=0

fail() {
  echo "$1" >&2
  failures=$((failures + 1))
}

require_file() {
  local file="$1"
  if [ ! -f "$file" ]; then
    fail "missing file: $file"
  fi
}

require_pattern() {
  local file="$1"
  local pattern="$2"
  local description="$3"
  if [ ! -f "$file" ]; then
    fail "missing file for pattern check: $file"
    return
  fi
  if ! grep -Eq -- "$pattern" "$file"; then
    fail "missing theme policy: $description"
  fi
}

forbid_pattern() {
  local file="$1"
  local pattern="$2"
  local description="$3"
  if [ ! -f "$file" ]; then
    return
  fi
  if grep -Eiq -- "$pattern" "$file"; then
    fail "forbidden theme policy: $description"
  fi
}

if [ "$theme_slug" != "yolkmeet-editorial" ]; then
  fail "baseline script must target yolkmeet-editorial, got: $theme_slug"
fi

require_file "$style_file"
require_file "$functions_file"
require_file "$index_file"
require_file "$single_file"
require_file "$theme_dir/page.php"
require_file "$archive_file"
require_file "$theme_dir/search.php"
require_file "$operator_style_file"
require_file "$operator_index_file"
require_file "$operator_author_box_file"
require_file "$operator_footer_file"

require_pattern "$style_file" 'Theme Name: Yolkmeet Editorial' "declares the custom theme"
require_pattern "$style_file" 'Author: YOLKMEET' "uses public brand casing in theme author metadata"
require_pattern "$style_file" 'operator-tech field guides|Operator-tech field guides' "uses broader operator-tech theme description"
require_pattern "$style_file" '--ink:[[:space:]]*#1D1B18' "uses Task 17 ink token"
require_pattern "$style_file" '--paper:[[:space:]]*#F8F5EF' "uses Task 17 paper token"
require_pattern "$style_file" '--accent:[[:space:]]*#0E6F68' "uses Task 17 teal accent"
require_pattern "$style_file" '--signal:[[:space:]]*#B84A2B' "uses Task 17 clay signal"
require_pattern "$style_file" '--article-width:[[:space:]]*720px' "sets article width"
require_pattern "$style_file" 'font-family:[^;]*(Newsreader|Georgia)' "uses serif display/article typography"
require_pattern "$style_file" 'letter-spacing:[[:space:]]*0' "keeps letter spacing neutral"
require_pattern "$style_file" '@media[^{]*max-width:[[:space:]]*640px' "has mobile breakpoint"
require_pattern "$style_file" 'overflow-x:[[:space:]]*auto' "lets wide tables scroll on mobile"
require_pattern "$style_file" '\.article-content table' "contains raw article tables without wrapper markup"
require_pattern "$style_file" '\.comparison-table table' "contains comparison tables without wrapper markup"
require_pattern "$style_file" 'min-width:[[:space:]]*0' "allows raw tables to shrink inside mobile viewport"
require_pattern "$style_file" 'breadcrumb' "styles breadcrumbs"
require_pattern "$style_file" 'source-note|update-log' "styles source notes or update logs"
require_pattern "$style_file" '--radius:[[:space:]]*6px|border-radius:[[:space:]]*(4|6|8)px' "uses square-ish radius"
require_pattern "$functions_file" "add_theme_support\\( *'title-tag'" "supports title tag"
require_pattern "$functions_file" 'register_nav_menus' "registers editorial navigation"
require_pattern "$functions_file" 'ca-pub-1424742974208042' "renders AdSense publisher verification snippet"
require_pattern "$functions_file" 'pagead2\.googlesyndication\.com/pagead/js/adsbygoogle\.js' "loads AdSense script from Google"
require_pattern "$functions_file" "add_action\\( *'wp_head'.*adsense" "prints AdSense verification snippet in the document head"
forbid_pattern "$functions_file" '<ins[^>]+adsbygoogle|adsbygoogle\\.push|data-ad-slot' "must not render live AdSense ad units before approval"
require_pattern "$functions_file" 'yolkmeet_editorial_breadcrumbs' "has breadcrumb helper"
require_pattern "$single_file" 'yolkmeet_editorial_breadcrumbs' "renders breadcrumbs on posts"
require_pattern "$single_file" 'source-note|update-log' "renders source notes or update log"
require_pattern "$single_file" 'YOLKMEET editorial desk' "uses public brand casing in author note"
forbid_pattern "$functions_file" 'Tested editorial format' "removes internal QA label from public post metadata"
forbid_pattern "$single_file" 'tested inputs|retested steps|Decision, setup notes' "removes internal workflow-review phrasing from public article chrome"
forbid_pattern "$index_file" 'review gates|QA patterns|Launch desk' "removes internal launch/editorial phrasing from public homepage chrome"
require_pattern "$index_file" 'Operator Tech Map|Browse by topic' "surfaces operator-tech topic discovery on the homepage"
require_pattern "$index_file" 'YOLKMEET tracks source-aware operator-tech guides' "uses public brand casing in homepage fallback"
require_pattern "$functions_file" 'How does YOLKMEET keep the guide current' "uses public brand casing in FAQ schema"
require_pattern "$theme_dir/footer.php" 'operator-tech field guides|Operator-tech field guides' "uses broader operator-tech footer positioning"
require_pattern "$operator_style_file" 'Author: YOLKMEET' "uses public brand casing in operator theme author metadata"
require_pattern "$operator_style_file" 'operator-tech field guides|Operator-tech field guides' "uses broader operator theme description"
require_pattern "$operator_index_file" 'YOLKMEET tracks source-aware operator-tech guides' "uses public brand casing in operator theme homepage fallback"
require_pattern "$operator_author_box_file" 'YOLKMEET articles are built' "uses public brand casing in operator theme author box"
require_pattern "$operator_footer_file" 'operator-tech field guides|Operator-tech field guides' "uses broader operator theme footer positioning"
for label in "Tool Comparisons" "Workflow Automation" "Research Playbooks" "Marketing Ops" "Prompt Systems"; do
  require_pattern "$index_file" "$label" "surfaces $label on the homepage"
done

forbid_pattern "$style_file" 'orb|glassmorphism|purple|#9b51e0|#6c5ce7|robot|fake dashboard|page-builder|nested-card' "blocks generic AI visual tropes"
forbid_pattern "$style_file" 'border-radius:[[:space:]]*(1[2-9]|[2-9][0-9])px' "blocks pill/card-heavy radius"
for file in "$functions_file" "$index_file" "$single_file" "$archive_file" "$style_file"; do
  forbid_pattern "$file" 'yolkmeet_editorial_render_ad_slot|YOLKMEET_SHOW_AD_PLACEHOLDERS|_yolkmeet_show_ad_placeholders|class="ad-slot|\.ad-slot|Advertisement' "removes visible/manual ad-slot UI from $(basename "$file")"
done

if [ "$failures" -ne 0 ]; then
  echo "theme baseline checks failed: $failures" >&2
  exit 1
fi

echo "desired theme baseline checks passed: yolkmeet-editorial files, tokens, breadcrumbs, source notes, operator-tech discovery, and Auto ads-only placement"
