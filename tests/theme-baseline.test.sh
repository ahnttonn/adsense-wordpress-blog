#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo_root/infra/configure-wordpress-baseline.sh"
theme_slug="$(awk -F= '$1 == "THEME_SLUG" {gsub(/"/, "", $2); print $2; exit}' "$script")"
theme_dir="$repo_root/wordpress/themes/$theme_slug"
style_file="$theme_dir/style.css"
functions_file="$theme_dir/functions.php"
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
require_file "$theme_dir/index.php"
require_file "$theme_dir/single.php"
require_file "$theme_dir/page.php"
require_file "$theme_dir/archive.php"
require_file "$theme_dir/search.php"

require_pattern "$style_file" 'Theme Name: Yolkmeet Editorial' "declares the custom theme"
require_pattern "$style_file" '--ink:[[:space:]]*#1D1B18' "uses Task 17 ink token"
require_pattern "$style_file" '--paper:[[:space:]]*#F8F5EF' "uses Task 17 paper token"
require_pattern "$style_file" '--accent:[[:space:]]*#0E6F68' "uses Task 17 teal accent"
require_pattern "$style_file" '--signal:[[:space:]]*#B84A2B' "uses Task 17 clay signal"
require_pattern "$style_file" '--article-width:[[:space:]]*720px' "sets article width"
require_pattern "$style_file" 'font-family:[^;]*(Newsreader|Georgia)' "uses serif display/article typography"
require_pattern "$style_file" 'letter-spacing:[[:space:]]*0' "keeps letter spacing neutral"
require_pattern "$style_file" '@media[^{]*max-width:[[:space:]]*640px' "has mobile breakpoint"
require_pattern "$style_file" 'overflow-x:[[:space:]]*auto' "lets wide tables scroll on mobile"
require_pattern "$style_file" 'min-height:[[:space:]]*(120|280)px' "reserves ad-slot height"
require_pattern "$style_file" 'breadcrumb' "styles breadcrumbs"
require_pattern "$style_file" 'source-note|update-log' "styles source notes or update logs"
require_pattern "$style_file" '--radius:[[:space:]]*6px|border-radius:[[:space:]]*(4|6|8)px' "uses square-ish radius"
require_pattern "$functions_file" "add_theme_support\\( *'title-tag'" "supports title tag"
require_pattern "$functions_file" 'register_nav_menus' "registers editorial navigation"
require_pattern "$functions_file" 'ca-pub-1424742974208042' "renders AdSense publisher verification snippet"
require_pattern "$functions_file" 'pagead2\.googlesyndication\.com/pagead/js/adsbygoogle\.js' "loads AdSense script from Google"
require_pattern "$functions_file" "add_action\\( *'wp_head'" "prints AdSense verification snippet in the document head"
require_pattern "$functions_file" 'yolkmeet_editorial_render_ad_slot' "has reusable ad-safe slot helper"
require_pattern "$functions_file" 'yolkmeet_editorial_breadcrumbs' "has breadcrumb helper"
require_pattern "$theme_dir/single.php" 'yolkmeet_editorial_breadcrumbs' "renders breadcrumbs on posts"
require_pattern "$theme_dir/single.php" 'source-note|update-log' "renders source notes or update log"
require_pattern "$theme_dir/index.php" 'organic_count' "counts organic homepage items before an in-feed ad"
require_pattern "$theme_dir/index.php" 'homepage feed after six organic items' "places homepage ad only after six organic items"

forbid_pattern "$style_file" 'orb|glassmorphism|purple|#9b51e0|#6c5ce7|robot|fake dashboard|page-builder|nested-card' "blocks generic AI visual tropes"
forbid_pattern "$style_file" 'border-radius:[[:space:]]*(1[2-9]|[2-9][0-9])px' "blocks pill/card-heavy radius"
forbid_pattern "$theme_dir/index.php" 'homepage feed after lead' "blocks homepage ad directly after the lead story"

if [ "$failures" -ne 0 ]; then
  echo "theme baseline checks failed: $failures" >&2
  exit 1
fi

echo "desired theme baseline checks passed: yolkmeet-editorial files, tokens, breadcrumbs, source notes, and ad-safe placeholders"
