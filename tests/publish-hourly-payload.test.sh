#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
queue_script="$repo_root/infra/hourly-publishing-queue.sh"
publish_script="$repo_root/infra/publish-hourly-payload.sh"
fixture="$repo_root/tests/fixtures/hourly-publishing/valid-draft.md"
tmp_dir="${TMPDIR:-/tmp}/yolkmeet-publish-hourly-test-$$"
failures=0

fail() {
  echo "$1" >&2
  failures=$((failures + 1))
}

trap 'rm -rf "$tmp_dir"' EXIT
mkdir -p "$tmp_dir/payload" "$tmp_dir/rendered"

bash -n "$publish_script" || fail "publish script syntax failed"

if ! bash "$queue_script" --dry-run --candidate "$fixture" --output-dir "$tmp_dir/payload" >"$tmp_dir/queue.out" 2>"$tmp_dir/queue.err"; then
  sed -n '1,120p' "$tmp_dir/queue.err" >&2
  fail "fixture payload generation failed"
fi

payload="$tmp_dir/payload/wp-draft-payload.json"
[ -f "$payload" ] || fail "payload missing"

if ! bash "$publish_script" --dry-run --payload "$payload" --output-dir "$tmp_dir/rendered" >"$tmp_dir/publish.out" 2>"$tmp_dir/publish.err"; then
  sed -n '1,120p' "$tmp_dir/publish.err" >&2
  fail "publish dry-run failed"
fi

content="$tmp_dir/rendered/post-content.html"
summary="$tmp_dir/rendered/publish-summary.json"
[ -f "$content" ] || fail "rendered content missing"
[ -f "$summary" ] || fail "publish summary missing"
grep -Fq '<!-- wp:heading -->' "$content" || fail "rendered content missing heading block"
grep -Fq '<!-- wp:html -->' "$content" || fail "rendered content missing HTML block for table"
grep -Fq '<table>' "$content" || fail "rendered content missing table"
jq -e '.status == "draft" and .slug == "hourly-publishing-valid-draft"' "$summary" >/dev/null || fail "summary missing draft slug"

if bash "$publish_script" --payload "$payload" --status private >"$tmp_dir/bad-status.out" 2>"$tmp_dir/bad-status.err"; then
  fail "unsupported status unexpectedly passed"
fi
grep -Fq 'unsupported --status' "$tmp_dir/bad-status.err" || fail "bad status reason missing"

if [ "$failures" -ne 0 ]; then
  echo "publish hourly payload checks failed: $failures" >&2
  exit 1
fi

echo "publish hourly payload checks passed: render dry-run, metadata summary, invalid status block"
