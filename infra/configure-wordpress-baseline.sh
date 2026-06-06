#!/usr/bin/env bash
set -euo pipefail

WP_ROOT="${WP_ROOT:-/var/www/yolkmeet.com}"
WP_USER="${WP_USER:-wpdeploy}"
THEME_SLUG="yolkmeet-editorial"
THEME_SOURCE="${THEME_SOURCE:-/tmp/$THEME_SLUG}"
SEO_PLUGIN="autodescription"
SECURITY_PLUGIN="limit-login-attempts-reloaded"
REDIS_PLUGIN="redis-cache"
SITE_URL="https://www.yolkmeet.com"
TOPIC_CATEGORY_SLUGS=(ai-tool-comparisons ai-workflow-automation ai-research-playbooks ai-marketing-ops ai-prompt-systems)

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root." >&2
    exit 1
  fi
}

wp_cli() {
  sudo -u "$WP_USER" wp --path="$WP_ROOT" "$@"
}

guard_plugin_baseline() {
  local blocked_plugins
  blocked_plugins="$(wp_cli plugin list --field=name | grep -E '^(elementor|divi|beaver-builder|visual-composer|rank-math|wordpress-seo|aioseo|seopress|w3-total-cache|wp-super-cache|litespeed-cache|wp-rocket)$' || true)"
  if [ -n "$blocked_plugins" ]; then
    echo "Blocked overlapping or heavy plugin families detected:" >&2
    echo "$blocked_plugins" >&2
    exit 1
  fi
}

install_theme() {
  if [ ! -d "$THEME_SOURCE" ]; then
    echo "Theme source missing: $THEME_SOURCE" >&2
    exit 1
  fi
  install -d -m 0755 -o "$WP_USER" -g www-data "$WP_ROOT/wp-content/themes/$THEME_SLUG"
  rsync -a --delete "$THEME_SOURCE/" "$WP_ROOT/wp-content/themes/$THEME_SLUG/"
  chown -R "$WP_USER":www-data "$WP_ROOT/wp-content/themes/$THEME_SLUG"
  wp_cli theme activate "$THEME_SLUG"
}

configure_plugins() {
  guard_plugin_baseline
  if ! wp_cli plugin is-installed "$SEO_PLUGIN"; then
    wp_cli plugin install "$SEO_PLUGIN"
  fi
  wp_cli plugin activate "$SEO_PLUGIN"
  if ! wp_cli plugin is-installed "$SECURITY_PLUGIN"; then
    wp_cli plugin install "$SECURITY_PLUGIN"
  fi
  wp_cli plugin activate "$SECURITY_PLUGIN"
  if wp_cli plugin is-installed "$REDIS_PLUGIN"; then
    wp_cli plugin activate "$REDIS_PLUGIN"
    wp_cli redis enable || true
  fi
}

ensure_page() {
  local title="$1"
  local slug="$2"
  local content="$3"
  local existing_id
  existing_id="$(wp_cli post list --post_type=page --name="$slug" --field=ID | head -n 1 || true)"
  if [ -n "$existing_id" ]; then
    wp_cli post update "$existing_id" --post_title="$title" --post_content="$content" --post_status=publish >/dev/null
  else
    wp_cli post create --post_type=page --post_title="$title" --post_name="$slug" --post_content="$content" --post_status=publish >/dev/null
  fi
}

topic_label() {
  case "$1" in
    ai-tool-comparisons) printf 'Tool Comparisons' ;;
    ai-workflow-automation) printf 'Workflow Automation' ;;
    ai-research-playbooks) printf 'Research Playbooks' ;;
    ai-marketing-ops) printf 'Marketing Ops' ;;
    ai-prompt-systems) printf 'Prompt Systems' ;;
    *)
      echo "Unknown topic category slug: $1" >&2
      exit 1
      ;;
  esac
}

topic_description() {
  case "$1" in
    ai-tool-comparisons) printf 'Tool comparisons, pricing checks, alternatives, and fit notes for operators choosing a workflow layer.' ;;
    ai-workflow-automation) printf 'Workflow automation guides for repeatable systems, review gates, and operator-ready execution.' ;;
    ai-research-playbooks) printf 'Research playbooks for source-aware investigation, verification steps, and reusable evidence trails.' ;;
    ai-marketing-ops) printf 'Marketing operations notes for campaign workflows, reporting loops, and lightweight content systems.' ;;
    ai-prompt-systems) printf 'Prompt systems, reusable templates, QA patterns, and review-ready AI operating procedures.' ;;
    *)
      echo "Unknown topic category slug: $1" >&2
      exit 1
      ;;
  esac
}

ensure_categories() {
  local slug term_id
  for slug in "${TOPIC_CATEGORY_SLUGS[@]}"; do
    term_id="$(wp_cli term list category --slug="$slug" --field=term_id | head -n 1)"
    if [ -z "$term_id" ]; then
      wp_cli term create category "$(topic_label "$slug")" --slug="$slug" >/dev/null
      term_id="$(wp_cli term list category --slug="$slug" --field=term_id | head -n 1)"
    fi
    wp_cli term update category "$term_id" --name="$(topic_label "$slug")" --slug="$slug" --description="$(topic_description "$slug")" >/dev/null
  done
}

ensure_sample_post() {
  local slug="ai-workflow-automation-stack-starter"
  local post_id
  local content
  post_id="$(wp_cli post list --post_type=post --name="$slug" --field=ID | head -n 1 || true)"
  content='<!-- wp:paragraph --><p><strong>Quick answer:</strong> Start with one task capture tool, one automation runner, one AI workspace, and one review checklist. The stack is only useful when every automated step has a human-readable audit trail.</p><!-- /wp:paragraph --><!-- wp:heading --><h2>Starter stack</h2><!-- /wp:heading --><!-- wp:table --><figure class="wp-block-table"><table><thead><tr><th>Layer</th><th>Role</th><th>Selection rule</th></tr></thead><tbody><tr><td>Capture</td><td>Collect repeatable requests</td><td>Prefer tools with exportable logs.</td></tr><tr><td>Automation</td><td>Run the workflow</td><td>Use versioned recipes and rollback notes.</td></tr><tr><td>AI workspace</td><td>Draft and compare options</td><td>Require source notes before publishing.</td></tr></tbody></table></figure><!-- /wp:table --><!-- wp:heading --><h2>Review checklist</h2><!-- /wp:heading --><!-- wp:preformatted --><pre>1. Verify source URLs\n2. Re-run the workflow\n3. Record changed assumptions\n4. Publish only after editorial review</pre><!-- /wp:preformatted --><!-- wp:paragraph --><p>This seed article exists to prove the editorial theme, comparison table, code block, category, and ad-safe article layout before the larger content batch is published.</p><!-- /wp:paragraph -->'
  if [ -n "$post_id" ]; then
    wp_cli post update "$post_id" --post_title="AI Workflow Automation Stack: Starter Notes" --post_content="$content" --post_status=publish >/dev/null
  else
    post_id="$(wp_cli post create --post_type=post --post_title="AI Workflow Automation Stack: Starter Notes" --post_name="$slug" --post_excerpt="A practical starter stack for AI workflow automation with review gates, comparison rules, and audit notes." --post_content="$content" --post_status=publish --porcelain)"
  fi
  wp_cli post term set "$post_id" category "$(wp_cli term list category --slug=ai-workflow-automation --field=term_id | head -n 1)" >/dev/null
}

configure_site_options() {
  wp_cli option update blogname "YOLKMEET" >/dev/null
  wp_cli option update blogdescription "Operator-tech field guides, automation playbooks, and workflow comparisons" >/dev/null
  wp_cli option update home "$SITE_URL" >/dev/null
  wp_cli option update siteurl "$SITE_URL" >/dev/null
  wp_cli option update blog_public 1 >/dev/null
  wp_cli option update permalink_structure '/%category%/%postname%/' >/dev/null
}

delete_managed_menus() {
  local menu_slug
  for menu_slug in primary topics footer; do
    if wp_cli menu list --field=slug | grep -Fxq "$menu_slug"; then
      wp_cli menu delete "$menu_slug" >/dev/null || true
    fi
  done
}

configure_nav() {
  local menu_id topics_id footer_id slug term_id

  delete_managed_menus

  menu_id="$(wp_cli menu create Primary --porcelain)"
  wp_cli menu item add-post "$menu_id" "$(wp_cli post list --post_type=page --name=about --field=ID | head -n 1)" --title=About >/dev/null || true
  wp_cli menu item add-post "$menu_id" "$(wp_cli post list --post_type=page --name=contact --field=ID | head -n 1)" --title=Contact >/dev/null || true
  wp_cli menu location assign "$menu_id" primary >/dev/null

  topics_id="$(wp_cli menu create Topics --porcelain)"
  for slug in "${TOPIC_CATEGORY_SLUGS[@]}"; do
    term_id="$(wp_cli term list category --slug="$slug" --field=term_id | head -n 1)"
    if [ -n "$term_id" ]; then
      wp_cli menu item add-term "$topics_id" category "$term_id" --title="$(topic_label "$slug")" >/dev/null || true
    fi
  done
  wp_cli menu location assign "$topics_id" topics >/dev/null

  footer_id="$(wp_cli menu create Footer --porcelain)"
  wp_cli menu item add-post "$footer_id" "$(wp_cli post list --post_type=page --name=privacy --field=ID | head -n 1)" --title=Privacy >/dev/null || true
  wp_cli menu item add-post "$footer_id" "$(wp_cli post list --post_type=page --name=contact --field=ID | head -n 1)" --title=Contact >/dev/null || true
  wp_cli menu location assign "$footer_id" footer >/dev/null
}

purge_fastcgi_cache() {
  if [ -d /var/cache/nginx/yolkmeet ]; then
    find /var/cache/nginx/yolkmeet -type f -delete
  fi
}

main() {
  require_root
  configure_site_options
  ensure_categories
  ensure_page "About" "about" "<p>YOLKMEET publishes practical operator-tech field guides, automation playbooks, workflow comparisons, and source-aware editorial notes for operators, creators, and small teams.</p><p>Each guide is designed to show what changed, what can be verified from public sources, and what readers should check before adopting a workflow.</p>"
  ensure_page "Contact" "contact" "<p>Send corrections, tool updates, and partnership questions to <a href=\"mailto:editor@yolkmeet.com\">editor@yolkmeet.com</a>.</p><p>For article corrections, include the URL, the claim, and the source that should be reviewed.</p>"
  ensure_page "Privacy" "privacy" "<p>YOLKMEET uses privacy-conscious analytics, server logs, security tooling, and Google AdSense after approval. Personal data collection is limited to what is needed to operate the publication, respond to reader messages, measure site performance, and maintain security.</p><p>YOLKMEET currently uses an AdSense-only monetization model and does not use affiliate links, sponsored placements, paid recommendations, or paid template funnels.</p>"
  ensure_sample_post
  install_theme
  configure_plugins
  configure_nav
  purge_fastcgi_cache
  wp_cli plugin list --format=csv
  wp_cli theme list --format=csv
}

main "$@"
