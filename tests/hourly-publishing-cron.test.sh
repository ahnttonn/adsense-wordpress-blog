#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo_root/infra/hourly-publishing-cron.sh"
fixture_dir="$repo_root/tests/fixtures/hourly-publishing"
tmp_dir="${TMPDIR:-/tmp}/yolkmeet-hourly-cron-test-$$"
failures=0

fail() {
  echo "$1" >&2
  failures=$((failures + 1))
}

trap 'rm -rf "$tmp_dir"' EXIT
mkdir -p "$tmp_dir/queue/ready" "$tmp_dir/evidence"

cp "$fixture_dir/valid-draft.md" "$tmp_dir/queue/ready/001-valid-draft.md"

if ! YOLKMEET_AUTO_WP_PUBLISH=0 YOLKMEET_HOURLY_QUEUE_DIR="$tmp_dir/queue" YOLKMEET_HOURLY_EVIDENCE_DIR="$tmp_dir/evidence" bash "$script" >"$tmp_dir/valid.out" 2>"$tmp_dir/valid.err"; then
  sed -n '1,120p' "$tmp_dir/valid.err" >&2
  fail "cron wrapper failed valid draft"
fi

find "$tmp_dir/queue/processed" -maxdepth 1 -name '*001-valid-draft.md' | grep -q . || fail "valid draft was not moved to processed"
find "$tmp_dir/evidence" -path '*/wp-draft-payload.json' -print -quit | grep -q . || fail "valid draft payload missing"
! find "$tmp_dir/evidence" -path '*/wp-draft-payload.json' -exec grep -Eq '"status"[[:space:]]*:[[:space:]]*"publish"' {} \; -print | grep -q . || fail "cron wrapper produced publish payload"

cp "$fixture_dir/missing-approval.md" "$tmp_dir/queue/ready/002-missing-approval.md"
if YOLKMEET_AUTO_WP_PUBLISH=0 YOLKMEET_HOURLY_QUEUE_DIR="$tmp_dir/queue" YOLKMEET_HOURLY_EVIDENCE_DIR="$tmp_dir/evidence" bash "$script" >"$tmp_dir/blocked.out" 2>"$tmp_dir/blocked.err"; then
  fail "cron wrapper unexpectedly passed missing approval draft"
fi
find "$tmp_dir/queue/blocked" -maxdepth 1 -name '*002-missing-approval.md' | grep -q . || fail "failed draft was not moved to blocked"

if ! YOLKMEET_AUTO_WP_PUBLISH=0 YOLKMEET_HOURLY_QUEUE_DIR="$tmp_dir/empty-queue" YOLKMEET_HOURLY_EVIDENCE_DIR="$tmp_dir/empty-evidence" bash "$script" >"$tmp_dir/noop.out" 2>"$tmp_dir/noop.err"; then
  fail "empty queue should be a no-op success"
fi
grep -Fq 'noop: no approved candidate markdown found' "$tmp_dir/noop.out" || fail "empty queue no-op was not observable"

if [ "$failures" -ne 0 ]; then
  echo "hourly publishing cron checks failed: $failures" >&2
  exit 1
fi

echo "hourly publishing cron checks passed: valid processed, invalid blocked, empty queue noop"
