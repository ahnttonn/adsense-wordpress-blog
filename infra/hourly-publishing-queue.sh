#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
quality_gate="$repo_root/infra/content-quality-gate.sh"
originality_check="$repo_root/infra/content-originality-check.sh"
seo_gate="$repo_root/tests/seo-aeo-geo-readiness.test.sh"
dry_run=false
candidate=""
output_dir=""
rollback_scheduler=false

usage() {
  echo "usage: $0 --dry-run (--candidate <markdown-file> | --rollback-scheduler) --output-dir <dir>" >&2
}

fail() {
  echo "blocked: $1" >&2
  exit "${2:-1}"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run)
      dry_run=true
      shift
      ;;
    --candidate)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      candidate="$2"
      shift 2
      ;;
    --output-dir)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      output_dir="$2"
      shift 2
      ;;
    --rollback-scheduler)
      rollback_scheduler=true
      shift
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

[ "$dry_run" = true ] || fail "hourly queue only supports --dry-run in this repository" 2
[ -n "$output_dir" ] || fail "missing --output-dir" 2
mkdir -p "$output_dir"
log_file="$output_dir/hourly-publishing-queue.log"

if [ "$rollback_scheduler" = true ]; then
  {
    echo "ROLLBACK-SCHEDULER: dry-run"
    echo "would disable hourly scheduler"
    echo "would not delete content"
    echo "would not modify WordPress posts"
  } | tee "$log_file"
  exit 0
fi

[ -n "$candidate" ] || fail "missing --candidate" 2
[ -f "$candidate" ] || fail "candidate not found: $candidate" 2
[ -r "$candidate" ] || fail "candidate unreadable: $candidate" 2

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
  ' "$candidate"
}

approval="$(front_matter_value publishing_approval || true)"
[ "$approval" = "approved" ] || fail "missing publishing approval metadata"

{
  echo "candidate=$candidate"
  echo "gate=content-quality"
} >"$log_file"
bash "$quality_gate" "$candidate" >>"$log_file" 2>&1 || fail "content quality gate failed"

echo "gate=originality" >>"$log_file"
bash "$originality_check" "$candidate" >>"$log_file" 2>&1 || fail "originality checker failed"

echo "gate=seo-aeo-geo" >>"$log_file"
bash "$seo_gate" "$candidate" >>"$log_file" 2>&1 || fail "SEO/AEO/GEO gate failed"

"$repo_root/infra/ai-publishing-dry-run.sh" "$candidate" "$output_dir" >>"$log_file" 2>&1 || fail "draft payload generation failed"

payload="$output_dir/wp-draft-payload.json"
[ -f "$payload" ] || fail "draft payload missing after dry-run"
if grep -Eq '"status"[[:space:]]*:[[:space:]]*"publish"' "$payload"; then
  fail "hourly queue must not create publish payload"
fi

echo "hourly queue complete: draft payload written to $payload"
