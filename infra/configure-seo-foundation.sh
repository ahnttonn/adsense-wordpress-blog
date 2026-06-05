#!/usr/bin/env bash
set -euo pipefail

WP_ROOT="${WP_ROOT:-/var/www/yolkmeet.com}"
WP_USER="${WP_USER:-wpdeploy}"
SITE_URL="https://www.yolkmeet.com"
SAMPLE_POST_SLUG="ai-workflow-automation-stack-starter"
SAMPLE_CATEGORY_SLUG="ai-workflow-automation"
SAMPLE_CATEGORY_NAME="AI Workflow Automation"
PRIMARY_KEYWORD="ai workflow automation stack"
OFFICIAL_ARTICLE_DOC="https://developers.google.com/search/docs/appearance/structured-data/article"
OFFICIAL_ROBOTS_DOC="https://developers.google.com/search/docs/crawling-indexing/robots-meta-tag"
OFFICIAL_AI_FEATURES_DOC="https://developers.google.com/search/docs/appearance/ai-features"

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root." >&2
    exit 1
  fi
}

wp_cli() {
  sudo -u "$WP_USER" wp --path="$WP_ROOT" "$@"
}

ensure_public_crawl_options() {
  wp_cli option update blog_public 1 >/dev/null
  wp_cli option update permalink_structure '/%category%/%postname%/' >/dev/null
}

ensure_category() {
  if [ -z "$(wp_cli term list category --slug="$SAMPLE_CATEGORY_SLUG" --field=term_id | head -n 1)" ]; then
    wp_cli term create category "$SAMPLE_CATEGORY_NAME" --slug="$SAMPLE_CATEGORY_SLUG" >/dev/null
  fi
}

sample_source_urls() {
  printf '%s\n' \
    "$OFFICIAL_ARTICLE_DOC" \
    "$OFFICIAL_ROBOTS_DOC" \
    "$OFFICIAL_AI_FEATURES_DOC"
}

sample_post_content() {
  cat <<'EOF'
<!-- wp:paragraph --><p><strong>Direct answer:</strong> Start with one task capture tool, one automation runner, one AI workspace, and one review checklist. The stack is only useful when every automated step has a human-readable audit trail and a source note that a teammate can verify.</p><!-- /wp:paragraph -->
<!-- wp:heading --><h2>Starter stack</h2><!-- /wp:heading -->
<!-- wp:table --><figure class="wp-block-table"><table><thead><tr><th>Layer</th><th>Role</th><th>Selection rule</th></tr></thead><tbody><tr><td>Capture</td><td>Collect repeatable requests</td><td>Prefer tools with exportable logs.</td></tr><tr><td>Automation</td><td>Run the workflow</td><td>Use versioned recipes and rollback notes.</td></tr><tr><td>AI workspace</td><td>Draft and compare options</td><td>Require source notes before publishing.</td></tr></tbody></table></figure><!-- /wp:table -->
<!-- wp:heading --><h2>Evidence and citations</h2><!-- /wp:heading -->
<!-- wp:paragraph --><p>This launch article follows Google guidance for Article structured data, robots meta snippet controls, and AI feature visibility. The source URLs are stored in post metadata and shown in the article source notes.</p><!-- /wp:paragraph -->
<!-- wp:heading --><h2>Review checklist</h2><!-- /wp:heading -->
<!-- wp:preformatted --><pre>1. Verify source URLs
2. Re-run the workflow
3. Record changed assumptions
4. Publish only after editorial review</pre><!-- /wp:preformatted -->
<!-- wp:heading --><h2>Frequently asked questions</h2><!-- /wp:heading -->
<!-- wp:paragraph --><p><strong>What should I verify first?</strong> Confirm crawler access, permalink behavior, source URLs, and the date of the last workflow retest.</p><!-- /wp:paragraph -->
<!-- wp:paragraph --><p><strong>When should the stack change?</strong> Replace a tool only when it improves the audit trail, lowers manual review risk, or handles a workflow requirement the current stack cannot meet.</p><!-- /wp:paragraph -->
EOF
}

ensure_sample_post() {
  local post_id
  local content
  post_id="$(wp_cli post list --post_type=post --name="$SAMPLE_POST_SLUG" --field=ID | head -n 1 || true)"
  content="$(sample_post_content)"

  if [ -n "$post_id" ]; then
    wp_cli post update "$post_id" \
      --post_title="AI Workflow Automation Stack: Starter Notes" \
      --post_excerpt="A practical starter stack for AI workflow automation with review gates, comparison rules, source notes, and update assumptions." \
      --post_content="$content" \
      --post_status=publish >/dev/null
  else
    post_id="$(wp_cli post create \
      --post_type=post \
      --post_title="AI Workflow Automation Stack: Starter Notes" \
      --post_name="$SAMPLE_POST_SLUG" \
      --post_excerpt="A practical starter stack for AI workflow automation with review gates, comparison rules, source notes, and update assumptions." \
      --post_content="$content" \
      --post_status=publish \
      --porcelain)"
  fi

  wp_cli post term set "$post_id" category "$SAMPLE_CATEGORY_NAME" >/dev/null
  wp_cli post meta update "$post_id" _yolkmeet_primary_keyword "$PRIMARY_KEYWORD" >/dev/null
  wp_cli post meta update "$post_id" _yolkmeet_source_urls "$(sample_source_urls)" >/dev/null
  wp_cli post meta update "$post_id" _yolkmeet_last_reviewed "$(date -u +%Y-%m-%d)" >/dev/null
}

print_verification_targets() {
  printf 'blog_public=%s\n' "$(wp_cli option get blog_public)"
  printf 'permalink_structure=%s\n' "$(wp_cli option get permalink_structure)"
  printf 'wp-sitemap=%s/wp-sitemap.xml\n' "$SITE_URL"
  printf 'sitemap-index=%s/sitemap.xml\n' "$SITE_URL"
  printf 'sample-post=%s/%s/%s/\n' "$SITE_URL" "$SAMPLE_CATEGORY_SLUG" "$SAMPLE_POST_SLUG"
}

main() {
  require_root
  ensure_public_crawl_options
  ensure_category
  ensure_sample_post
  print_verification_targets
}

main "$@"
