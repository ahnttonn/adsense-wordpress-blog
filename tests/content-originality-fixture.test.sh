#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
checker="$repo_root/infra/content-originality-check.sh"
fixture_dir="$repo_root/tests/fixtures/content"
benchmark_fixture="$fixture_dir/benchmark-copied-paragraph.txt"
good_fixture="$fixture_dir/original-good.md"
copied_fixture="$fixture_dir/copied-benchmark-risk.md"
prompt_injection_fixture="$fixture_dir/prompt-injection-source.md"
malformed_manifest="$fixture_dir/malformed-manifest-row.tsv"
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

run_checker() {
  local fixture="$1"
  local output_file="$2"

  bash "$checker" "$fixture" >"$output_file" 2>&1
}

assert_file "$checker" "content originality checker"
assert_file "$benchmark_fixture" "benchmark copied paragraph fixture"
assert_file "$good_fixture" "original content fixture"
assert_file "$copied_fixture" "copied benchmark risk fixture"
assert_file "$prompt_injection_fixture" "prompt injection source fixture"
assert_file "$malformed_manifest" "malformed manifest row fixture"

if [ -f "$benchmark_fixture" ] && [ -f "$copied_fixture" ]; then
  if ! grep -Ff "$benchmark_fixture" "$copied_fixture" >/dev/null 2>&1; then
    fail "copied benchmark fixture does not contain the benchmark paragraph"
  fi
fi

if [ -f "$benchmark_fixture" ] && [ -f "$good_fixture" ]; then
  if grep -Ff "$benchmark_fixture" "$good_fixture" >/dev/null 2>&1; then
    fail "original-good fixture contains the benchmark paragraph"
  fi
fi

if [ -f "$checker" ]; then
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT

  if ! run_checker "$good_fixture" "$tmp_dir/good.out"; then
    sed -n '1,80p' "$tmp_dir/good.out" >&2
    fail "originality checker rejected original-good.md"
  fi

  if run_checker "$copied_fixture" "$tmp_dir/copied.out"; then
    sed -n '1,80p' "$tmp_dir/copied.out" >&2
    fail "originality checker allowed copied-benchmark-risk.md"
  fi

  if run_checker "$prompt_injection_fixture" "$tmp_dir/prompt-injection.out"; then
    sed -n '1,80p' "$tmp_dir/prompt-injection.out" >&2
    fail "originality checker allowed prompt-injection-source.md"
  fi
fi

if [ "$failures" -ne 0 ]; then
  echo "Content originality fixture checks failed: $failures" >&2
  exit 1
fi

echo "Content originality fixture checks passed: original fixture accepted; copied benchmark and prompt injection fixtures blocked"
