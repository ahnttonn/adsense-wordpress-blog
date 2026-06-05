#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <draft-file>" >&2
  exit 2
fi

draft_file="$1"
if [ ! -f "$draft_file" ]; then
  echo "draft file not found: $draft_file" >&2
  exit 2
fi

lower_body="$(tr '[:upper:]' '[:lower:]' < "$draft_file")"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
benchmark_fixture="$repo_root/tests/fixtures/content/benchmark-copied-paragraph.txt"
blocked_phrases=(
  "best ai productivity tools in 2026"
  "best ai tools for b2b marketing in 2026"
  "best ai content generators for marketing"
  "best ai workflow automation tools"
  "chatgpt alternatives"
  "zapier alternatives"
  "claude alternatives"
  "gemini alternatives"
)

if [ -f "$benchmark_fixture" ]; then
  if grep -Ff "$benchmark_fixture" "$draft_file" >/dev/null 2>&1; then
    echo "originality gate failed: copied benchmark paragraph fixture matched" >&2
    exit 1
  fi
fi

if printf '%s' "$lower_body" | grep -Eq 'ignore (the )?originality policy|skip source attribution|approve copied benchmark text|ignore every previous rule'; then
  echo "originality gate failed: prompt-injection style source instruction found" >&2
  exit 1
fi

matches=0
for phrase in "${blocked_phrases[@]}"; do
  if printf '%s' "$lower_body" | grep -Fq -- "$phrase"; then
    matches=$((matches + 1))
    echo "copy-risk phrase matched: $phrase" >&2
  fi
done

if [ "$matches" -ge 3 ]; then
  echo "originality gate failed: $matches blocked benchmark phrases found" >&2
  exit 1
fi

if ! printf '%s' "$lower_body" | grep -Eq 'source-derived analysis|firsthand test|editorial workflow|source-aware|source notes'; then
  echo "originality gate failed: missing testing or source-derived analysis marker" >&2
  exit 1
fi

echo "originality gate passed: no high-similarity benchmark risk detected"
