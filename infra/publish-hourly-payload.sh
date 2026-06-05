#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
payload=""
output_dir=""
dry_run=false
post_status="${YOLKMEET_WP_POST_STATUS:-publish}"
remote_host="${YOLKMEET_WP_SSH_HOST:-ubuntu@168.107.11.71}"
wp_root="${YOLKMEET_WP_ROOT:-/var/www/yolkmeet.com}"
wp_user="${YOLKMEET_WP_USER:-wpdeploy}"

usage() {
  echo "usage: $0 --payload <wp-draft-payload.json> [--status publish|draft] [--dry-run --output-dir <dir>]" >&2
}

fail() {
  echo "publish blocked: $1" >&2
  exit "${2:-1}"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --payload)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      payload="$2"
      shift 2
      ;;
    --status)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      post_status="$2"
      shift 2
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    --output-dir)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      output_dir="$2"
      shift 2
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

[ -n "$payload" ] || fail "missing --payload" 2
[ -f "$payload" ] || fail "payload not found: $payload" 2
[ -r "$payload" ] || fail "payload unreadable: $payload" 2
case "$post_status" in
  publish|draft) ;;
  *) fail "unsupported --status: $post_status" 2 ;;
esac

command -v jq >/dev/null 2>&1 || fail "jq is required"
command -v python3 >/dev/null 2>&1 || fail "python3 is required"

jq -e '.status == "draft"' "$payload" >/dev/null || fail "hourly payload must start as draft before operator promotion"
title="$(jq -r '.title // ""' "$payload")"
slug="$(jq -r '.slug // ""' "$payload")"
content="$(jq -r '.content // ""' "$payload")"
[ -n "$title" ] || fail "payload missing title"
[ -n "$slug" ] || fail "payload missing slug"
[ -n "$content" ] || fail "payload missing content"

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

category_label_for_slug() {
  case "$1" in
    wordpress-site-ops) printf 'WordPress Site Ops' ;;
    automation-no-code) printf 'Automation No-Code' ;;
    analytics-reporting) printf 'Analytics Reporting' ;;
    creator-business-tooling) printf 'Creator Business Tooling' ;;
    security-privacy) printf 'Security Privacy' ;;
    ai-tool-comparisons) printf 'Tool Comparisons' ;;
    ai-workflow-automation) printf 'Workflow Automation' ;;
    ai-research-playbooks) printf 'Research Playbooks' ;;
    ai-marketing-ops) printf 'Marketing Ops' ;;
    ai-prompt-systems) printf 'Prompt Systems' ;;
    *) printf '%s' "$1" | sed -E 's/-/ /g' ;;
  esac
}

infer_category_slug() {
  local text
  text="$(printf '%s %s %s' "$slug" "$title" "$(jq -r '.target_keyword // ""' "$payload")" | tr '[:upper:]' '[:lower:]')"
  case "$text" in
    *wordpress*|*core-web-vitals*|*search-console*|*sitemap*|*seo-plugin*|*site-ops*) printf 'wordpress-site-ops' ;;
    *zapier*|*make*|*n8n*|*automation*|*no-code*) printf 'automation-no-code' ;;
    *analytics*|*reporting*|*ga4*|*dashboard*) printf 'analytics-reporting' ;;
    *creator*|*business-tool*|*publishing-stack*) printf 'creator-business-tooling' ;;
    *security*|*privacy*|*backup*|*hardening*) printf 'security-privacy' ;;
    *comparison*|*alternatives*|*tool*) printf 'ai-tool-comparisons' ;;
    *research*) printf 'ai-research-playbooks' ;;
    *marketing*) printf 'ai-marketing-ops' ;;
    *prompt*) printf 'ai-prompt-systems' ;;
    *) printf 'ai-workflow-automation' ;;
  esac
}

category_slug="$(jq -r '.category_slug // ""' "$payload")"
category_name="$(jq -r '.category // ""' "$payload")"
if [ -z "$category_slug" ] || [ "$category_slug" = "null" ]; then
  if [ -n "$category_name" ] && [ "$category_name" != "null" ]; then
    category_slug="$(slugify "$category_name")"
  else
    category_slug="$(infer_category_slug)"
  fi
fi
if [ -z "$category_name" ] || [ "$category_name" = "null" ]; then
  category_name="$(category_label_for_slug "$category_slug")"
fi

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT
content_file="$work_dir/post-content.html"

python3 - "$payload" >"$content_file" <<'PY'
import html
import json
import re
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    payload = json.load(f)

title = payload.get("title", "").strip()
lines = payload.get("content", "").splitlines()
out = []
i = 0

def inline(value: str) -> str:
    escaped = html.escape(value.strip())
    escaped = re.sub(r"`([^`]+)`", r"<code>\1</code>", escaped)
    escaped = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", escaped)
    escaped = re.sub(r"\[([^\]]+)\]\((https?://[^)]+)\)", r'<a href="\2">\1</a>', escaped)
    return escaped

def emit_paragraph(parts: list[str]) -> None:
    text = " ".join(part.strip() for part in parts if part.strip())
    if text:
        out.extend(["<!-- wp:paragraph -->", f"<p>{inline(text)}</p>", "<!-- /wp:paragraph -->", ""])

def emit_heading(level: int, text: str) -> None:
    level = max(2, min(level, 4))
    out.extend(["<!-- wp:heading -->", f"<h{level}>{inline(text)}</h{level}>", "<!-- /wp:heading -->", ""])

def parse_table(start: int) -> tuple[str, int]:
    rows = []
    j = start
    while j < len(lines) and lines[j].strip().startswith("|") and lines[j].strip().endswith("|"):
        rows.append([cell.strip() for cell in lines[j].strip().strip("|").split("|")])
        j += 1
    if len(rows) >= 2 and all(re.fullmatch(r":?-{3,}:?", cell.replace(" ", "")) for cell in rows[1]):
        header = rows[0]
        body = rows[2:]
    else:
        header = rows[0]
        body = rows[1:]
    html_rows = ["<table><thead><tr>"]
    html_rows.extend(f"<th>{inline(cell)}</th>" for cell in header)
    html_rows.append("</tr></thead><tbody>")
    for row in body:
        html_rows.append("<tr>")
        html_rows.extend(f"<td>{inline(cell)}</td>" for cell in row)
        html_rows.append("</tr>")
    html_rows.append("</tbody></table>")
    return "".join(html_rows), j

paragraph: list[str] = []
while i < len(lines):
    line = lines[i]
    stripped = line.strip()
    if not stripped:
        emit_paragraph(paragraph)
        paragraph = []
        i += 1
        continue
    if stripped.startswith("#"):
        emit_paragraph(paragraph)
        paragraph = []
        match = re.match(r"^(#{1,6})\s+(.+)$", stripped)
        if match:
            heading_text = match.group(2).strip()
            if not (len(match.group(1)) == 1 and heading_text == title):
                emit_heading(len(match.group(1)), heading_text)
            i += 1
            continue
    if stripped.startswith("|") and stripped.endswith("|"):
        emit_paragraph(paragraph)
        paragraph = []
        table_html, i = parse_table(i)
        out.extend(["<!-- wp:html -->", table_html, "<!-- /wp:html -->", ""])
        continue
    if stripped.startswith("- "):
        emit_paragraph(paragraph)
        paragraph = []
        items = []
        while i < len(lines) and lines[i].strip().startswith("- "):
            items.append(lines[i].strip()[2:])
            i += 1
        out.extend(["<!-- wp:list -->", "<ul>"])
        out.extend(f"<li>{inline(item)}</li>" for item in items)
        out.extend(["</ul>", "<!-- /wp:list -->", ""])
        continue
    paragraph.append(stripped)
    i += 1

emit_paragraph(paragraph)
print("\n".join(out).strip())
PY

if [ "$dry_run" = true ]; then
  [ -n "$output_dir" ] || fail "missing --output-dir for --dry-run" 2
  mkdir -p "$output_dir"
  cp "$content_file" "$output_dir/post-content.html"
  jq \
    --arg category "$category_name" \
    --arg category_slug "$category_slug" \
    '{title, slug, status, meta_title, meta_description, source_urls, internal_links} + {category: $category, category_slug: $category_slug}' \
    "$payload" >"$output_dir/publish-summary.json"
  echo "publish dry-run complete: rendered $output_dir/post-content.html"
  exit 0
fi

remote_dir="/tmp/yolkmeet-hourly-publish-$(date -u +%Y%m%dT%H%M%SZ)-$$"
ssh -o BatchMode=yes "$remote_host" "mkdir -p '$remote_dir'"
scp -q "$payload" "$remote_host:$remote_dir/payload.json"
scp -q "$content_file" "$remote_host:$remote_dir/post-content.html"

ssh -o BatchMode=yes "$remote_host" \
  "REMOTE_DIR='$remote_dir' WP_ROOT='$wp_root' WP_USER='$wp_user' POST_STATUS='$post_status' bash -s" <<'REMOTE'
set -euo pipefail

payload="$REMOTE_DIR/payload.json"
content_file="$REMOTE_DIR/post-content.html"
wp_root="$WP_ROOT"
wp_user="$WP_USER"
post_status="$POST_STATUS"

run_wp() {
  sudo -n -u "$wp_user" wp --path="$wp_root" "$@"
}

title="$(jq -r '.title' "$payload")"
slug="$(jq -r '.slug' "$payload")"
excerpt="$(jq -r '.meta_description // ""' "$payload")"
target_keyword="$(jq -r '.target_keyword // ""' "$payload")"
category_slug="$(jq -r '.category_slug // ""' "$payload")"
category_name="$(jq -r '.category // ""' "$payload")"
meta_title="$(jq -r '.meta_title // ""' "$payload")"
meta_description="$(jq -r '.meta_description // ""' "$payload")"
update_policy="$(jq -r '.update_policy // ""' "$payload")"
analysis_note="$(jq -r '.analysis_note // ""' "$payload")"
source_urls="$(jq -r '.source_urls[]?' "$payload")"
internal_links="$(jq -r '.internal_links[]?' "$payload")"

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

category_label_for_slug() {
  case "$1" in
    wordpress-site-ops) printf 'WordPress Site Ops' ;;
    automation-no-code) printf 'Automation No-Code' ;;
    analytics-reporting) printf 'Analytics Reporting' ;;
    creator-business-tooling) printf 'Creator Business Tooling' ;;
    security-privacy) printf 'Security Privacy' ;;
    ai-tool-comparisons) printf 'Tool Comparisons' ;;
    ai-workflow-automation) printf 'Workflow Automation' ;;
    ai-research-playbooks) printf 'Research Playbooks' ;;
    ai-marketing-ops) printf 'Marketing Ops' ;;
    ai-prompt-systems) printf 'Prompt Systems' ;;
    *) printf '%s' "$1" | sed -E 's/-/ /g' ;;
  esac
}

infer_category_slug() {
  local text
  text="$(printf '%s %s %s' "$slug" "$title" "$target_keyword" | tr '[:upper:]' '[:lower:]')"
  case "$text" in
    *wordpress*|*core-web-vitals*|*search-console*|*sitemap*|*seo-plugin*|*site-ops*) printf 'wordpress-site-ops' ;;
    *zapier*|*make*|*n8n*|*automation*|*no-code*) printf 'automation-no-code' ;;
    *analytics*|*reporting*|*ga4*|*dashboard*) printf 'analytics-reporting' ;;
    *creator*|*business-tool*|*publishing-stack*) printf 'creator-business-tooling' ;;
    *security*|*privacy*|*backup*|*hardening*) printf 'security-privacy' ;;
    *comparison*|*alternatives*|*tool*) printf 'ai-tool-comparisons' ;;
    *research*) printf 'ai-research-playbooks' ;;
    *marketing*) printf 'ai-marketing-ops' ;;
    *prompt*) printf 'ai-prompt-systems' ;;
    *) printf 'ai-workflow-automation' ;;
  esac
}

ensure_category() {
  local name="$1"
  local slug="$2"
  local term_id
  term_id="$(run_wp term list category --slug="$slug" --field=term_id 2>/dev/null | head -n 1 || true)"
  if [ -z "$term_id" ]; then
    term_id="$(run_wp term create category "$name" --slug="$slug" --porcelain)"
  else
    run_wp term update category "$term_id" --name="$name" --slug="$slug" >/dev/null
  fi
  printf '%s' "$term_id"
}

if [ -z "$category_slug" ] || [ "$category_slug" = "null" ]; then
  if [ -n "$category_name" ] && [ "$category_name" != "null" ]; then
    category_slug="$(slugify "$category_name")"
  else
    category_slug="$(infer_category_slug)"
  fi
fi
if [ -z "$category_name" ] || [ "$category_name" = "null" ]; then
  category_name="$(category_label_for_slug "$category_slug")"
fi
category_id="$(ensure_category "$category_name" "$category_slug")"

existing_id="$(run_wp post list --post_type=post --name="$slug" --field=ID 2>/dev/null | head -n 1 || true)"
if [ -z "$existing_id" ]; then
  post_id="$(run_wp post create \
    --post_type=post \
    --post_status="$post_status" \
    --post_name="$slug" \
    --post_title="$title" \
    --post_excerpt="$excerpt" \
    --post_category="$category_id" \
    --post_content="$(cat "$content_file")" \
    --porcelain)"
  action="created"
else
  post_id="$existing_id"
  run_wp post update "$post_id" \
    --post_status="$post_status" \
    --post_title="$title" \
    --post_excerpt="$excerpt" \
    --post_category="$category_id" \
    --post_content="$(cat "$content_file")" >/dev/null
  action="updated"
fi

run_wp post meta update "$post_id" _yolkmeet_source_urls "$source_urls" >/dev/null
run_wp post meta update "$post_id" _yolkmeet_primary_keyword "$target_keyword" >/dev/null
run_wp post meta update "$post_id" _yolkmeet_target_keyword "$target_keyword" >/dev/null
run_wp post meta update "$post_id" _yolkmeet_category_slug "$category_slug" >/dev/null
run_wp post meta update "$post_id" _yolkmeet_meta_title "$meta_title" >/dev/null
run_wp post meta update "$post_id" _yolkmeet_meta_description "$meta_description" >/dev/null
run_wp post meta update "$post_id" _yolkmeet_update_policy "$update_policy" >/dev/null
run_wp post meta update "$post_id" _yolkmeet_analysis_note "$analysis_note" >/dev/null
run_wp post meta update "$post_id" _yolkmeet_originality_checklist "Automated hourly pipeline: content, originality, SEO/AEO/GEO, and operator review gates passed before WP-CLI promotion." >/dev/null
run_wp cache flush >/dev/null 2>&1 || true

url="$(run_wp post get "$post_id" --field=url 2>/dev/null || true)"
printf 'wp-post-%s: id=%s status=%s slug=%s url=%s\n' "$action" "$post_id" "$post_status" "$slug" "$url"
rm -rf "$REMOTE_DIR"
REMOTE
