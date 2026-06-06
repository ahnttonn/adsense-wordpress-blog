#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
doc="$repo_root/docs/daily-ops-audit.md"
script="$repo_root/infra/daily-ops-audit.sh"
tmp_dir="${TMPDIR:-/tmp}/yolkmeet-daily-ops-test-$$"
failures=0

fail() {
  echo "$1" >&2
  failures=$((failures + 1))
}

require_file() {
  local file="$1"
  local description="$2"
  [ -f "$file" ] || fail "missing daily ops artifact: $description"
}

require_pattern() {
  local file="$1"
  local pattern="$2"
  local description="$3"
  if ! grep -Eq -- "$pattern" "$file"; then
    fail "missing daily ops evidence: $description"
  fi
}

forbid_pattern() {
  local file="$1"
  local pattern="$2"
  local description="$3"
  if grep -Eiq -- "$pattern" "$file"; then
    fail "forbidden daily ops behavior: $description"
  fi
}

trap 'rm -rf "$tmp_dir"' EXIT
mkdir -p "$tmp_dir/evidence"

require_file "$doc" "daily ops docs"
require_file "$script" "daily ops read-only script"

if [ -f "$script" ]; then
  bash -n "$script" || fail "daily ops script shell syntax"
fi

if [ -f "$doc" ]; then
  require_pattern "$doc" 'read-only by default' "read-only boundary"
  require_pattern "$doc" 'create an ULW plan only if' "plan-only escalation"
  require_pattern "$doc" 'must not mutate WordPress' "no production mutation"
  require_pattern "$doc" 'content/distribution-queue/ready' "distribution brief review queue"
fi

if [ -f "$script" ]; then
  forbid_pattern "$script" 'wp post update|wp post create|wp option update|publish-hourly-payload|git push|git commit' "mutation command in read-only audit"
  YOLKMEET_DAILY_OPS_SKIP_HTTP=1 YOLKMEET_DAILY_OPS_EVIDENCE_DIR="$tmp_dir/evidence" bash "$script" >"$tmp_dir/run.out" 2>"$tmp_dir/run.err" || fail "daily ops audit script failed"
  find "$tmp_dir/evidence" -type f -name '*summary.md' -print -quit | grep -q . || fail "daily ops summary evidence missing"
  grep -Fq 'HTTP checks skipped by YOLKMEET_DAILY_OPS_SKIP_HTTP=1' "$tmp_dir/run.out" || fail "skip-http mode not observable"
fi

if [ "$failures" -ne 0 ]; then
  echo "daily ops audit checks failed: $failures" >&2
  exit 1
fi

echo "daily ops audit checks passed: docs, read-only script, evidence output, and no mutation commands"
