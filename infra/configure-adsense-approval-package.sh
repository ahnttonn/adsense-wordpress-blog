#!/usr/bin/env bash
set -euo pipefail

WP_ROOT="${WP_ROOT:-/var/www/yolkmeet.com}"
WP_USER="${WP_USER:-wpdeploy}"
SITE_URL="${SITE_URL:-https://www.yolkmeet.com}"
ADSENSE_PUBLISHER_ID="${ADSENSE_PUBLISHER_ID:-}"
APPLICATION_BOUNDARY="AdSense application is account-gated"
TRUST_PAGE_SLUGS=("about" "contact" "privacy-policy" "terms" "editorial-policy" "ai-use-policy" "affiliate-disclosure" "cookie-policy")
FOOTER_PAGE_SLUGS=("privacy-policy" "terms" "editorial-policy" "ai-use-policy" "affiliate-disclosure" "cookie-policy")
TOPIC_CATEGORY_SLUGS=(ai-tool-comparisons ai-workflow-automation ai-research-playbooks ai-marketing-ops ai-prompt-systems)

usage() {
  cat <<'EOF'
Usage: configure-adsense-approval-package.sh

Publishes the fixed YOLKMEET trust-page set and navigation required for
AdSense readiness. This script accepts no page slug or title arguments.

Optional environment:
  WP_ROOT=/var/www/yolkmeet.com
  WP_USER=wpdeploy
  SITE_URL=https://www.yolkmeet.com
  ADSENSE_PUBLISHER_ID=pub-0000000000000000
EOF
}

reject_unsupported_args() {
  if [ "$#" -eq 0 ]; then
    return
  fi

  usage >&2
  printf 'Unsupported input: page slugs and titles are fixed for Task 9 trust pages.\n' >&2
  exit 2
}

wp_cli() {
  if command -v sudo >/dev/null 2>&1 && id "$WP_USER" >/dev/null 2>&1 && [ "$(id -un)" != "$WP_USER" ]; then
    sudo -u "$WP_USER" wp --path="$WP_ROOT" "$@"
  else
    wp --path="$WP_ROOT" "$@"
  fi
}

ensure_page() {
  local title="$1"
  local slug="$2"
  local content="$3"
  local existing_id

  existing_id="$(wp_cli post list --post_type=page --name="$slug" --format=ids 2>/dev/null | awk '{ print $1; exit }' || true)"
  if [ -n "$existing_id" ]; then
    wp_cli post update "$existing_id" \
      --post_title="$title" \
      --post_name="$slug" \
      --post_content="$content" \
      --post_status=publish >/dev/null
  else
    wp_cli post create \
      --post_type=page \
      --post_title="$title" \
      --post_name="$slug" \
      --post_content="$content" \
      --post_status=publish >/dev/null
  fi
}

page_content() {
  local slug="$1"

  case "$slug" in
    "about")
      cat <<'EOF'
<!-- wp:paragraph --><p>YOLKMEET publishes English-first practical operator-tech field guides, automation playbooks, workflow comparisons, site operations notes, analytics/reporting guides, prompt workflows, and source-aware AI tool coverage for operators, creators, and small teams.</p><!-- /wp:paragraph -->
<!-- wp:paragraph --><p>Our articles are built around clear decisions, source URLs, review notes, and update logs so readers can verify the assumptions before adopting a workflow.</p><!-- /wp:paragraph -->
EOF
      ;;
    "contact")
      cat <<'EOF'
<!-- wp:paragraph --><p>Send corrections, source updates, disclosure questions, and partnership inquiries to <a href="mailto:editor@yolkmeet.com">editor@yolkmeet.com</a>.</p><!-- /wp:paragraph -->
<!-- wp:paragraph --><p>For article corrections, include the page URL, the claim that should be reviewed, and the source that supports the change. We review corrections before changing published guidance.</p><!-- /wp:paragraph -->
EOF
      ;;
    "privacy-policy")
      cat <<'EOF'
<!-- wp:paragraph --><p>YOLKMEET collects only the information needed to operate the publication, respond to reader messages, measure site performance, and maintain security. If you email editor@yolkmeet.com, we receive the information you choose to send.</p><!-- /wp:paragraph -->
<!-- wp:paragraph --><p>The site may use privacy-conscious analytics, server logs, security tooling, and Google advertising technologies after AdSense approval. Advertising partners may use cookies or similar technologies to measure ad delivery and prevent invalid activity.</p><!-- /wp:paragraph -->
<!-- wp:paragraph --><p>We do not sell reader contact details. Readers can request correction or deletion of direct contact messages by emailing editor@yolkmeet.com.</p><!-- /wp:paragraph -->
EOF
      ;;
    "terms")
      cat <<'EOF'
<!-- wp:paragraph --><p>YOLKMEET provides editorial information about operator technology, automation workflows, site operations, analytics/reporting, AI tools, prompt systems, and productivity systems. The content is for general informational use and is not legal, financial, medical, or professional advice.</p><!-- /wp:paragraph -->
<!-- wp:paragraph --><p>Readers are responsible for checking pricing, product terms, security requirements, and compliance obligations before adopting any workflow. Tool availability and policies can change after publication.</p><!-- /wp:paragraph -->
<!-- wp:paragraph --><p>Do not misuse this site, attempt to bypass security controls, scrape pages in a way that disrupts service, or submit unlawful material through contact channels.</p><!-- /wp:paragraph -->
EOF
      ;;
    "editorial-policy")
      cat <<'EOF'
<!-- wp:paragraph --><p>YOLKMEET editorial policy starts with a reader problem, then records source URLs, source notes, decision criteria, caveats, and an update policy. We prioritize official documentation, public product pages, and reproducible workflow evidence over broad unsupported claims.</p><!-- /wp:paragraph -->
<!-- wp:paragraph --><p>Competitor pages may be used for market research, search intent mapping, and format benchmarking, but their article bodies are not copied into publishable drafts.</p><!-- /wp:paragraph -->
<!-- wp:paragraph --><p>AI-assisted drafts are reviewed for usefulness, copied-body risk, unsupported claims, internal links, corrections, and review status before publication. We avoid fake freshness, invented citations, and claims of firsthand testing unless a real test artifact exists.</p><!-- /wp:paragraph -->
<!-- wp:paragraph --><p>When a material error is found, we review the source, update the article, and keep the update log visible where the article template supports it.</p><!-- /wp:paragraph -->
EOF
      ;;
    "ai-use-policy")
      cat <<'EOF'
<!-- wp:paragraph --><p>YOLKMEET may use AI systems to help research public sources, organize outlines, draft first passes, compare wording, and check internal consistency. AI output is not treated as a source of truth.</p><!-- /wp:paragraph -->
<!-- wp:paragraph --><p>Published articles must preserve source URLs, source notes, editorial review, and update assumptions. We do not intentionally publish copied article bodies, fabricated citations, or unsupported product claims generated by automation.</p><!-- /wp:paragraph -->
<!-- wp:paragraph --><p>Readers should verify tool behavior in their own accounts because AI products, pricing, and policy details can change quickly.</p><!-- /wp:paragraph -->
EOF
      ;;
    "affiliate-disclosure")
      cat <<'EOF'
<!-- wp:paragraph --><p>YOLKMEET currently uses an AdSense-only monetization model. The site does not currently use affiliate links, sponsored placements, paid recommendations, or paid template funnels.</p><!-- /wp:paragraph -->
<!-- wp:paragraph --><p>Advertising decisions must not control editorial recommendations or remove the requirement for source-aware analysis, caveats, and editorial review. The site does not ask readers to click ads or use manufactured traffic to influence AdSense, analytics, or ranking signals.</p><!-- /wp:paragraph -->
EOF
      ;;
    "cookie-policy")
      cat <<'EOF'
<!-- wp:paragraph --><p>YOLKMEET may use cookies or similar technologies for site security, basic preferences, analytics, and advertising after AdSense approval. Advertising cookies may be used by Google AdSense after approval to help measure ad delivery and prevent invalid traffic.</p><!-- /wp:paragraph -->
<!-- wp:paragraph --><p>Readers can control cookies through browser settings. If additional consent tooling becomes required for a region or advertising partner, YOLKMEET will update this page and the site interface before relying on that consent path.</p><!-- /wp:paragraph -->
EOF
      ;;
    *)
      echo "Unknown trust page slug: $slug" >&2
      exit 1
      ;;
  esac
}

page_title() {
  local slug="$1"

  case "$slug" in
    "about") printf 'About' ;;
    "contact") printf 'Contact' ;;
    "privacy-policy") printf 'Privacy Policy' ;;
    "terms") printf 'Terms of Use' ;;
    "editorial-policy") printf 'Editorial Policy' ;;
    "ai-use-policy") printf 'AI Use Policy' ;;
    "affiliate-disclosure") printf 'Affiliate Disclosure' ;;
    "cookie-policy") printf 'Cookie Policy' ;;
    *)
      echo "Unknown trust page slug: $slug" >&2
      exit 1
      ;;
  esac
}

ensure_trust_pages() {
  local slug

  for slug in "${TRUST_PAGE_SLUGS[@]}"; do
    ensure_page "$(page_title "$slug")" "$slug" "$(page_content "$slug")"
  done
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

ensure_topic_categories() {
  local slug category_id

  for slug in "${TOPIC_CATEGORY_SLUGS[@]}"; do
    category_id="$(category_id_by_slug "$slug")"
    if [ -z "$category_id" ]; then
      wp_cli term create category "$(topic_label "$slug")" --slug="$slug" >/dev/null
      category_id="$(category_id_by_slug "$slug")"
    fi
    wp_cli term update category "$category_id" --name="$(topic_label "$slug")" --slug="$slug" --description="$(topic_description "$slug")" >/dev/null
  done
}

delete_managed_menus() {
  local menu_ids
  local menu_id
  local menu_slug
  for menu_slug in primary topics footer; do
    menu_ids="$(wp_cli menu list --format=csv | awk -F, -v slug="$menu_slug" 'NR > 1 && $3 == slug {print $1}')"
    for menu_id in $menu_ids; do
      wp_cli menu delete "$menu_id" >/dev/null || true
    done
  done
}

page_id_by_slug() {
  wp_cli post list --post_type=page --name="$1" --format=ids | awk '{ print $1; exit }'
}

category_id_by_slug() {
  wp_cli term list category --slug="$1" --format=ids | awk '{ print $1; exit }'
}

configure_nav() {
  local menu_id topics_id footer_id
  local category_id
  local footer_slug topic_slug

  delete_managed_menus

  menu_id="$(wp_cli menu create Primary --porcelain)"
  wp_cli menu item add-post "$menu_id" "$(page_id_by_slug about)" --title=About >/dev/null
  wp_cli menu item add-post "$menu_id" "$(page_id_by_slug contact)" --title=Contact >/dev/null
  wp_cli menu location assign "$menu_id" primary >/dev/null

  topics_id="$(wp_cli menu create Topics --porcelain)"
  for topic_slug in "${TOPIC_CATEGORY_SLUGS[@]}"; do
    category_id="$(category_id_by_slug "$topic_slug")"
    if [ -n "$category_id" ]; then
      wp_cli menu item add-term "$topics_id" category "$category_id" --title="$(topic_label "$topic_slug")" >/dev/null
    fi
  done
  wp_cli menu location assign "$topics_id" topics >/dev/null

  footer_id="$(wp_cli menu create Footer --porcelain)"
  for footer_slug in "${FOOTER_PAGE_SLUGS[@]}"; do
    wp_cli menu item add-post "$footer_id" "$(page_id_by_slug "$footer_slug")" --title="$(page_title "$footer_slug")" >/dev/null
  done
  wp_cli menu location assign "$footer_id" footer >/dev/null
}

configure_ads_txt_readiness() {
  local ads_txt_path="$WP_ROOT/ads.txt"

  if [ "$ADSENSE_PUBLISHER_ID" = "" ]; then
    printf 'ads.txt readiness: ADSENSE_PUBLISHER_ID not provided; no ads.txt changes made before user-owned account approval\n'
    return
  fi

  if ! printf '%s' "$ADSENSE_PUBLISHER_ID" | grep -Eq '^pub-[0-9]{16}$'; then
    printf 'Invalid ADSENSE_PUBLISHER_ID: expected pub- followed by 16 digits\n' >&2
    exit 1
  fi

  printf 'google.com, %s, DIRECT, f08c47fec0942fa0\n' "$ADSENSE_PUBLISHER_ID" >"$ads_txt_path"
  printf 'ads.txt readiness: wrote %s for Google AdSense publisher ID\n' "$ads_txt_path"
}

purge_fastcgi_cache() {
  if [ -d /var/cache/nginx/yolkmeet ]; then
    find /var/cache/nginx/yolkmeet -type f -delete
  fi
}

main() {
  reject_unsupported_args "$@"
  ensure_trust_pages
  ensure_topic_categories
  configure_nav
  configure_ads_txt_readiness
  purge_fastcgi_cache
  wp_cli cache flush >/dev/null 2>&1 || true
  printf 'AdSense approval package configured for %s\n' "$SITE_URL"
  printf '%s\n' "$APPLICATION_BOUNDARY"
}

main "$@"
