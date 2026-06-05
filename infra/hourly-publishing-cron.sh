#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
queue_dir="${YOLKMEET_HOURLY_QUEUE_DIR:-$repo_root/content/hourly-queue}"
ready_dir="$queue_dir/ready"
processed_dir="$queue_dir/processed"
blocked_dir="$queue_dir/blocked"
evidence_root="${YOLKMEET_HOURLY_EVIDENCE_DIR:-$repo_root/.omo/evidence/hourly-publishing-cron}"
lock_dir="${TMPDIR:-/tmp}/yolkmeet-hourly-publishing.lock"

timestamp() {
  date -u +%Y%m%dT%H%M%SZ
}

log() {
  printf '%s %s\n' "$(timestamp)" "$*"
}

if ! mkdir "$lock_dir" 2>/dev/null; then
  log "skip: previous hourly publishing run is still active"
  exit 0
fi
trap 'rm -rf "$lock_dir"' EXIT

mkdir -p "$ready_dir" "$processed_dir" "$blocked_dir" "$evidence_root"

candidate="$(find "$ready_dir" -maxdepth 1 -type f -name '*.md' | sort | sed -n '1p')"
if [ -z "$candidate" ]; then
  log "noop: no approved candidate markdown found in $ready_dir"
  exit 0
fi

run_id="$(timestamp)"
candidate_name="$(basename "$candidate")"
candidate_stem="${candidate_name%.md}"
run_dir="$evidence_root/$run_id-$candidate_stem"
mkdir -p "$run_dir"

log "candidate=$candidate"
if bash "$repo_root/infra/hourly-publishing-queue.sh" --dry-run --candidate "$candidate" --output-dir "$run_dir" >"$run_dir/stdout.log" 2>"$run_dir/stderr.log"; then
  payload="$run_dir/wp-draft-payload.json"
  if [ "${YOLKMEET_AUTO_WP_PUBLISH:-1}" = "1" ]; then
    bash "$repo_root/infra/publish-hourly-payload.sh" --payload "$payload" --status "${YOLKMEET_WP_POST_STATUS:-publish}" >"$run_dir/wp-publish.log" 2>"$run_dir/wp-publish.err" || {
      status=$?
      mv "$candidate" "$blocked_dir/$run_id-$candidate_name"
      log "blocked: $candidate_name -> $blocked_dir/$run_id-$candidate_name"
      log "publish stderr: $run_dir/wp-publish.err"
      exit "$status"
    }
  else
    log "publish skipped: YOLKMEET_AUTO_WP_PUBLISH is not 1"
  fi
  mv "$candidate" "$processed_dir/$run_id-$candidate_name"
  log "processed: $candidate_name -> $processed_dir/$run_id-$candidate_name"
  log "payload: $payload"
  exit 0
else
  status=$?
fi

mv "$candidate" "$blocked_dir/$run_id-$candidate_name"
log "blocked: $candidate_name -> $blocked_dir/$run_id-$candidate_name"
log "stderr: $run_dir/stderr.log"
exit "$status"
