#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo_root/infra/indexnow-readiness-check.sh"
tmp_dir="${TMPDIR:-/tmp}/yolkmeet-indexnow-test-$$"
failures=0

fail() {
  echo "$1" >&2
  failures=$((failures + 1))
}

trap 'rm -rf "$tmp_dir"' EXIT
mkdir -p "$tmp_dir"

key_file="$tmp_dir/indexnow-test-key.txt"
printf 'indexnow-test-key\n' >"$key_file"

if [ ! -f "$script" ]; then
  fail "missing IndexNow readiness script"
else
  bash -n "$script" || fail "IndexNow readiness script syntax"
fi

if ! bash "$script" --dry-run --key-file "$key_file" --url "https://www.yolkmeet.com/operator-tech/test-page/" >"$tmp_dir/dry-run.out" 2>"$tmp_dir/dry-run.err"; then
  sed -n '1,120p' "$tmp_dir/dry-run.err" >&2
  fail "IndexNow dry-run unexpectedly failed"
fi

if [ -f "$tmp_dir/dry-run.out" ]; then
  grep -Fq 'https://api.indexnow.org/indexnow' "$tmp_dir/dry-run.out" || fail "dry-run endpoint missing"
  grep -Fq 'https%3A%2F%2Fwww.yolkmeet.com%2Foperator-tech%2Ftest-page%2F' "$tmp_dir/dry-run.out" || fail "dry-run URL was not encoded"
  grep -Fq 'key=indexnow-test-key' "$tmp_dir/dry-run.out" || fail "dry-run key missing"
fi

if bash "$script" --dry-run --key-file "$tmp_dir/missing-key.txt" --url "https://www.yolkmeet.com/operator-tech/test-page/" >"$tmp_dir/missing-key.out" 2>"$tmp_dir/missing-key.err"; then
  fail "missing key file unexpectedly succeeded"
fi

if bash "$script" --dry-run --key-file "$key_file" --url "https://example.com/operator-tech/test-page/" >"$tmp_dir/foreign.out" 2>"$tmp_dir/foreign.err"; then
  fail "foreign host unexpectedly succeeded"
fi

if bash "$script" --dry-run --event cosmetic --key-file "$key_file" --url "https://www.yolkmeet.com/operator-tech/test-page/" >"$tmp_dir/cosmetic.out" 2>"$tmp_dir/cosmetic.err"; then
  fail "cosmetic-only event unexpectedly submitted"
fi

if [ "$failures" -ne 0 ]; then
  echo "IndexNow readiness checks failed: $failures" >&2
  exit 1
fi

echo "IndexNow readiness checks passed: dry-run payload, key guard, host guard, and cosmetic-change block"
