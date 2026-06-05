#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
design_doc="$repo_root/docs/ai-publishing-automation.md"
dry_run_script="$repo_root/infra/ai-publishing-dry-run.sh"
publish_script="$repo_root/infra/publish-launch-batch.sh"
quality_gate="$repo_root/infra/content-quality-gate.sh"
originality_check="$repo_root/infra/content-originality-check.sh"
fixture_dir="$repo_root/tests/fixtures/content-quality"
tmp_dir="${TMPDIR:-/tmp}/yolkmeet-task11-test-$$"
failures=0

fail() {
  echo "$1" >&2
  failures=$((failures + 1))
}

assert_file() {
  local path="$1"
  local description="$2"
  if [ ! -f "$path" ]; then
    fail "missing $description: $path"
  fi
}

assert_contains() {
  local body="$1"
  local needle="$2"
  local description="$3"
  if ! printf '%s' "$body" | grep -Fq -- "$needle"; then
    fail "missing automation design evidence: $description"
  fi
}

assert_file "$design_doc" "AI publishing automation design doc"
assert_file "$dry_run_script" "AI publishing dry-run script"
assert_file "$publish_script" "launch publisher"
assert_file "$quality_gate" "content quality gate"
assert_file "$originality_check" "originality checker"

if [ -f "$dry_run_script" ]; then
  mkdir -p "$tmp_dir"

  if "$dry_run_script" "$fixture_dir/copied-draft.md" "$tmp_dir/copied" >"$tmp_dir/copied.out" 2>"$tmp_dir/copied.err"; then
    fail "copied content fixture unexpectedly passed dry-run"
  elif [ -f "$tmp_dir/copied/wp-draft-payload.json" ]; then
    fail "copied content fixture created a WordPress payload"
  elif ! grep -Eq 'copied|originality|blocked' "$tmp_dir/copied.err"; then
    fail "copied content block reason was not observable"
  fi

  if "$dry_run_script" "$fixture_dir/prompt-injection-draft.md" "$tmp_dir/injection" >"$tmp_dir/injection.out" 2>"$tmp_dir/injection.err"; then
    fail "prompt injection fixture unexpectedly passed dry-run"
  elif ! grep -Eq 'prompt-injection|originality|blocked' "$tmp_dir/injection.err"; then
    fail "prompt injection block reason was not observable"
  fi

  if ! "$dry_run_script" "$fixture_dir/original-draft.md" "$tmp_dir/original" >"$tmp_dir/original.out" 2>"$tmp_dir/original.err"; then
    fail "source-cited original fixture did not produce draft payload"
  else
    payload="$tmp_dir/original/wp-draft-payload.json"
    assert_file "$payload" "dry-run WordPress draft payload"
    if [ -f "$payload" ]; then
      grep -Eq '"status"[[:space:]]*:[[:space:]]*"draft"' "$payload" || fail "dry-run payload is not draft status"
      ! grep -Eq '"status"[[:space:]]*:[[:space:]]*"publish"' "$payload" || fail "dry-run payload must never publish"
      grep -Fq 'developers.google.com/search/docs/fundamentals/creating-helpful-content' "$payload" || fail "dry-run payload does not preserve source URLs"
    fi
  fi

  rm -rf "$tmp_dir"
fi

if [ "$failures" -ne 0 ]; then
  echo "automation publishing design checks failed: $failures" >&2
  exit 1
fi

echo "automation publishing design checks passed: design doc and pipeline gates are documented"
