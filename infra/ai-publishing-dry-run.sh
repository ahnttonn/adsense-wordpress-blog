#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: $0 <draft-file> <output-dir>" >&2
  exit 2
fi

draft_file="$1"
output_dir="$2"

if [ ! -f "$draft_file" ]; then
  echo "draft file not found: $draft_file" >&2
  exit 2
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
quality_gate="$repo_root/infra/content-quality-gate.sh"
originality_check="$repo_root/infra/content-originality-check.sh"

mkdir -p "$output_dir"

if ! bash "$quality_gate" "$draft_file"; then
  echo "dry-run blocked: originality or quality gate failed" >&2
  exit 1
fi

if ! bash "$originality_check" "$draft_file"; then
  echo "dry-run blocked: originality checker failed" >&2
  exit 1
fi

front_matter_value() {
  local key="$1"
  awk -v key="$key" '
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { exit }
    in_fm && index($0, key ":") == 1 {
      value = substr($0, length(key) + 2)
      sub(/^[[:space:]]+/, "", value)
      sub(/[[:space:]]+$/, "", value)
      gsub(/^"|"$/, "", value)
      print value
      exit
    }
  ' "$draft_file"
}

front_matter_list_json() {
  local key="$1"
  awk -v key="$key" '
    function esc(s) {
      gsub(/\\/, "\\\\", s)
      gsub(/"/, "\\\"", s)
      return s
    }
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { exit }
    in_fm && index($0, key ":") == 1 { in_list = 1; next }
    in_fm && in_list && $0 ~ /^[[:space:]]*-[[:space:]]+/ {
      item = $0
      sub(/^[[:space:]]*-[[:space:]]+/, "", item)
      gsub(/^"|"$/, "", item)
      if (count++) printf(",")
      printf("\"%s\"", esc(item))
    }
    in_fm && $0 ~ /^[A-Za-z_][A-Za-z0-9_]*:/ && index($0, key ":") != 1 { in_list = 0 }
  ' "$draft_file"
}

json_string() {
  python3 -c 'import json, sys; print(json.dumps(sys.stdin.read()))'
}

body="$(awk '
  NR == 1 && $0 == "---" { in_fm = 1; next }
  in_fm && $0 == "---" { in_body = 1; next }
  in_body { print }
' "$draft_file")"

title="$(front_matter_value title)"
slug="$(front_matter_value slug)"
target_keyword="$(front_matter_value target_keyword)"
meta_title="$(front_matter_value meta_title)"
meta_description="$(front_matter_value meta_description)"
update_policy="$(front_matter_value update_policy)"
analysis_note="$(front_matter_value analysis_note)"

source_urls_json="$(printf '%s' "$(front_matter_list_json source_urls)")"
internal_links_json="$(printf '%s' "$(front_matter_list_json internal_links)")"
body_json="$(printf '%s' "$body" | json_string)"

payload="$output_dir/wp-draft-payload.json"
cat >"$payload" <<EOF
{
  "status":"draft",
  "title":"$(printf '%s' "$title" | sed 's/\\/\\\\/g; s/"/\\"/g')",
  "slug":"$(printf '%s' "$slug" | sed 's/\\/\\\\/g; s/"/\\"/g')",
  "target_keyword":"$(printf '%s' "$target_keyword" | sed 's/\\/\\\\/g; s/"/\\"/g')",
  "meta_title":"$(printf '%s' "$meta_title" | sed 's/\\/\\\\/g; s/"/\\"/g')",
  "meta_description":"$(printf '%s' "$meta_description" | sed 's/\\/\\\\/g; s/"/\\"/g')",
  "update_policy":"$(printf '%s' "$update_policy" | sed 's/\\/\\\\/g; s/"/\\"/g')",
  "analysis_note":"$(printf '%s' "$analysis_note" | sed 's/\\/\\\\/g; s/"/\\"/g')",
  "source_urls":[${source_urls_json}],
  "internal_links":[${internal_links_json}],
  "content":${body_json}
}
EOF

echo "dry-run complete: draft-only payload written to $payload"
