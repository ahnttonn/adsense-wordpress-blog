#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
articles_file="${ARTICLES_FILE:-$repo_root/content/launch-batch/articles.tsv}"
wp_path="${WP_PATH:-/var/www/yolkmeet.com}"
site_url="${SITE_URL:-https://www.yolkmeet.com}"
wp_user="${WP_RUN_USER:-wpdeploy}"
last_reviewed="${LAST_REVIEWED:-2026-06-05}"

if [ ! -f "$articles_file" ]; then
  echo "articles file not found: $articles_file" >&2
  exit 1
fi

run_wp() {
  if command -v sudo >/dev/null 2>&1 && id "$wp_user" >/dev/null 2>&1 && [ "$(id -un)" != "$wp_user" ]; then
    sudo -u "$wp_user" wp --path="$wp_path" "$@"
  else
    wp --path="$wp_path" "$@"
  fi
}

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

escape_attr() {
  printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/"/\&quot;/g' -e "s/'/\&#39;/g" -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}

build_source_list() {
  local source_urls="$1"
  local html="<ul>"
  IFS='|' read -r -a sources <<< "$source_urls"
  for source_url in "${sources[@]}"; do
    html="$html<li><a href=\"$(escape_attr "$source_url")\">$(escape_attr "$source_url")</a></li>"
  done
  html="$html</ul>"
  printf '%s' "$html"
}

build_internal_links() {
  local internal_targets="$1"
  local html="<ul>"
  IFS='|' read -r -a targets <<< "$internal_targets"
  for target in "${targets[@]}"; do
    local target_slug="${target%%:*}"
    local target_category="${target#*:}"
    local target_title
    target_title="$(printf '%s' "$target_slug" | sed -E 's/-/ /g; s/\b(.)/\U\1/g')"
    html="$html<li><a href=\"$site_url/$target_category/$target_slug/\">$(escape_attr "$target_title")</a></li>"
  done
  html="$html</ul>"
  printf '%s' "$html"
}

build_content() {
  local title="$1"
  local target_keyword="$2"
  local template="$3"
  local update_policy="$4"
  local source_urls="$5"
  local internal_targets="$6"
  local analysis_note="$7"
  local evidence_note="$8"
  local decision="$9"
  local source_list
  local internal_links

  source_list="$(build_source_list "$source_urls")"
  internal_links="$(build_internal_links "$internal_targets")"

  cat <<EOF
<!-- wp:paragraph -->
<p><strong>Decision first:</strong> $(escape_attr "$decision") This launch guide targets the query <em>$(escape_attr "$target_keyword")</em> and is written as a practical operating note, not a copied ranking page.</p>
<!-- /wp:paragraph -->

<!-- wp:heading -->
<h2>Best-fit reader</h2>
<!-- /wp:heading -->
<!-- wp:paragraph -->
<p>This guide is for operators, creators, and small teams choosing AI tools with a bias toward repeatable workflows. It prioritizes source visibility, review gates, setup effort, and maintenance risk over broad claims that cannot be verified from public documentation.</p>
<!-- /wp:paragraph -->

<!-- wp:heading -->
<h2>Source-derived analysis</h2>
<!-- /wp:heading -->
<!-- wp:paragraph -->
<p>$(escape_attr "$analysis_note") The launch version uses official product and policy pages as primary evidence. Any hands-on screenshots or account-specific notes should be added only after a controlled test run is recorded in the editorial notes.</p>
<!-- /wp:paragraph -->

<!-- wp:heading -->
<h2>Decision table</h2>
<!-- /wp:heading -->
<!-- wp:html -->
<table><thead><tr><th>Question</th><th>What to verify</th><th>Why it matters</th></tr></thead><tbody><tr><td>Workflow fit</td><td>Map the tool to one daily job before comparing features.</td><td>Prevents listicle-style recommendations with no operating context.</td></tr><tr><td>Source quality</td><td>Check official docs, pricing pages, and product pages before claims.</td><td>Keeps the article useful for search and AI-answer citations.</td></tr><tr><td>Review gate</td><td>Decide who checks outputs before publishing or sending.</td><td>Reduces hallucination, policy, and automation risk.</td></tr><tr><td>Refresh need</td><td>Record how often the guide must be rechecked.</td><td>AI product pages change quickly and stale advice becomes harmful.</td></tr></tbody></table>
<!-- /wp:html -->

<!-- wp:heading -->
<h2>Practical workflow</h2>
<!-- /wp:heading -->
<!-- wp:list -->
<ol><li>Define the exact job the reader is trying to complete.</li><li>Collect official source URLs and reject unsupported claims.</li><li>Compare tools or steps against the workflow, not against vague popularity.</li><li>Write a first decision, then add caveats where pricing, policy, or access may change.</li><li>Schedule the refresh described in the update policy.</li></ol>
<!-- /wp:list -->

<!-- wp:heading -->
<h2>Evidence note</h2>
<!-- /wp:heading -->
<!-- wp:paragraph -->
<p>$(escape_attr "$evidence_note") Screenshot slots are intentionally left out unless a real account-level test has been captured; this prevents fake visual proof.</p>
<!-- /wp:paragraph -->

<!-- wp:heading -->
<h2>Internal reading path</h2>
<!-- /wp:heading -->
<!-- wp:html -->
$internal_links
<!-- /wp:html -->

<!-- wp:heading -->
<h2>Source log</h2>
<!-- /wp:heading -->
<!-- wp:html -->
$source_list
<!-- /wp:html -->

<!-- wp:heading -->
<h2>Originality checklist</h2>
<!-- /wp:heading -->
<!-- wp:list -->
<ul><li>No competitor body text was copied into this guide.</li><li>Claims are tied to source URLs or explicitly marked as Yolkmeet editorial criteria.</li><li>The article does not claim firsthand testing unless a test artifact exists.</li><li>Pricing and product details must be rechecked against official pages before updates.</li></ul>
<!-- /wp:list -->

<!-- wp:heading -->
<h2>Update policy</h2>
<!-- /wp:heading -->
<!-- wp:paragraph -->
<p>$(escape_attr "$update_policy") The editor should record changed assumptions, retested steps, and source revisions before changing the recommendation.</p>
<!-- /wp:paragraph -->
EOF
}

ensure_category() {
  local category="$1"
  local category_slug="$2"
  local category_id

  category_id="$(run_wp term list category --slug="$category_slug" --field=term_id 2>/dev/null | head -n 1 || true)"
  if [ "$category_id" = "" ]; then
    category_id="$(run_wp term create category "$category" --slug="$category_slug" --porcelain)"
  fi

  printf '%s' "$category_id"
}

published=0
updated=0

while IFS=$'\t' read -r slug title category target_keyword meta_title meta_description template update_policy source_urls internal_targets analysis_note evidence_note decision; do
  if [ "$slug" = "slug" ]; then
    continue
  fi

  category_slug="$(slugify "$category")"
  category_id="$(ensure_category "$category" "$category_slug")"
  post_content="$(build_content "$title" "$target_keyword" "$template" "$update_policy" "$source_urls" "$internal_targets" "$analysis_note" "$evidence_note" "$decision")"
  existing_id="$(run_wp post list --post_type=post --name="$slug" --field=ID 2>/dev/null | head -n 1 || true)"

  if [ "$existing_id" = "" ]; then
    post_id="$(run_wp post create \
      --post_type=post \
      --post_status=publish \
      --post_name="$slug" \
      --post_title="$title" \
      --post_excerpt="$meta_description" \
      --post_category="$category_id" \
      --post_content="$post_content" \
      --porcelain)"
    published=$((published + 1))
  else
    post_id="$existing_id"
    run_wp post update "$post_id" \
      --post_status=publish \
      --post_title="$title" \
      --post_excerpt="$meta_description" \
      --post_category="$category_id" \
      --post_content="$post_content" >/dev/null
    updated=$((updated + 1))
  fi

  run_wp post meta update "$post_id" _yolkmeet_source_urls "$(printf '%s' "$source_urls" | tr '|' '\n')" >/dev/null
  run_wp post meta update "$post_id" _yolkmeet_primary_keyword "$target_keyword" >/dev/null
  run_wp post meta update "$post_id" _yolkmeet_target_keyword "$target_keyword" >/dev/null
  run_wp post meta update "$post_id" _yolkmeet_last_reviewed "$last_reviewed" >/dev/null
  run_wp post meta update "$post_id" _yolkmeet_meta_title "$meta_title" >/dev/null
  run_wp post meta update "$post_id" _yolkmeet_meta_description "$meta_description" >/dev/null
  run_wp post meta update "$post_id" _yolkmeet_article_template "$template" >/dev/null
  run_wp post meta update "$post_id" _yolkmeet_internal_link_targets "$internal_targets" >/dev/null
  run_wp post meta update "$post_id" _yolkmeet_originality_checklist "No copied competitor body text; source-derived analysis marked; official source URLs recorded; unsupported claims avoided; refresh policy present." >/dev/null
  run_wp post meta update "$post_id" _yolkmeet_update_policy "$update_policy" >/dev/null
done < "$articles_file"

run_wp cache flush >/dev/null 2>&1 || true

echo "launch batch complete: published=$published updated=$updated"
