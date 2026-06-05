#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo_root/infra/hourly-publishing-queue.sh"
fixture_dir="$repo_root/tests/fixtures/hourly-publishing"
tmp_dir="${TMPDIR:-/tmp}/yolkmeet-hourly-queue-test-$$"
failures=0

fail() {
  echo "$1" >&2
  failures=$((failures + 1))
}

assert_file() {
  local path="$1"
  local description="$2"
  [ -f "$path" ] || fail "missing $description: $path"
}

assert_file "$script" "hourly publishing queue script"
assert_file "$fixture_dir/valid-draft.md" "valid hourly fixture"
assert_file "$fixture_dir/copied-body.md" "copied hourly fixture"
assert_file "$fixture_dir/missing-approval.md" "missing approval fixture"

mkdir -p "$tmp_dir"
trap 'rm -rf "$tmp_dir"' EXIT

if ! bash "$script" --dry-run --candidate "$fixture_dir/valid-draft.md" --output-dir "$tmp_dir/valid" >"$tmp_dir/valid.out" 2>"$tmp_dir/valid.err"; then
  sed -n '1,120p' "$tmp_dir/valid.err" >&2
  fail "valid hourly candidate did not produce draft payload"
else
  payload="$tmp_dir/valid/wp-draft-payload.json"
  assert_file "$payload" "valid draft payload"
  grep -Eq '"status"[[:space:]]*:[[:space:]]*"draft"' "$payload" || fail "valid payload is not draft"
  ! grep -Eq '"status"[[:space:]]*:[[:space:]]*"publish"' "$payload" || fail "valid payload must not publish"
fi

if bash "$script" --dry-run --candidate "$fixture_dir/copied-body.md" --output-dir "$tmp_dir/copied" >"$tmp_dir/copied.out" 2>"$tmp_dir/copied.err"; then
  fail "copied hourly fixture unexpectedly passed"
fi
[ ! -f "$tmp_dir/copied/wp-draft-payload.json" ] || fail "copied fixture created a payload"
grep -Eiq 'content quality|originality|copied|blocked' "$tmp_dir/copied.err" || fail "copied fixture error did not name a gate"

if bash "$script" --dry-run --candidate "$fixture_dir/missing-approval.md" --output-dir "$tmp_dir/missing" >"$tmp_dir/missing.out" 2>"$tmp_dir/missing.err"; then
  fail "missing approval fixture unexpectedly passed"
fi
[ ! -f "$tmp_dir/missing/wp-draft-payload.json" ] || fail "missing approval fixture created a payload"
grep -Fq 'missing publishing approval metadata' "$tmp_dir/missing.err" || fail "missing approval reason not observable"

if ! bash "$script" --dry-run --rollback-scheduler --output-dir "$tmp_dir/rollback" >"$tmp_dir/rollback.out" 2>"$tmp_dir/rollback.err"; then
  fail "rollback scheduler dry-run failed"
else
  grep -Fq 'would disable hourly scheduler' "$tmp_dir/rollback.out" || fail "rollback output missing scheduler disable receipt"
  grep -Fq 'would not delete content' "$tmp_dir/rollback.out" || fail "rollback output missing no-delete receipt"
fi

if [ "$failures" -ne 0 ]; then
  echo "hourly publishing queue checks failed: $failures" >&2
  exit 1
fi

echo "hourly publishing queue checks passed: valid draft payload, copied block, approval block, rollback dry-run"
