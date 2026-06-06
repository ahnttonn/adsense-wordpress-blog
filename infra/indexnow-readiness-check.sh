#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: indexnow-readiness-check.sh --dry-run --key-file <key-file> --url <url> [--event publish|update|delete|cosmetic]
EOF
}

dry_run=0
key_file=""
url=""
event="update"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run)
      dry_run=1
      shift
      ;;
    --key-file)
      key_file="${2:-}"
      shift 2
      ;;
    --url)
      url="${2:-}"
      shift 2
      ;;
    --event)
      event="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      echo "unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

[ "$dry_run" -eq 1 ] || { echo "live IndexNow submission is intentionally disabled; use --dry-run" >&2; exit 2; }
[ -n "$key_file" ] || { usage; echo "missing --key-file" >&2; exit 2; }
[ -n "$url" ] || { usage; echo "missing --url" >&2; exit 2; }
[ -f "$key_file" ] || { echo "IndexNow key file not found: $key_file" >&2; exit 2; }

case "$event" in
  publish|update|delete) ;;
  cosmetic)
    echo "cosmetic-only changes should not be submitted to IndexNow by default" >&2
    exit 2
    ;;
  *)
    echo "unsupported IndexNow event: $event" >&2
    exit 2
    ;;
esac

case "$url" in
  https://www.yolkmeet.com/*) ;;
  *)
    echo "IndexNow URL must be on https://www.yolkmeet.com/" >&2
    exit 2
    ;;
esac

key="$(tr -d '[:space:]' <"$key_file")"
[ -n "$key" ] || { echo "IndexNow key file is empty: $key_file" >&2; exit 2; }

encoded_url="$(python3 - "$url" <<'PY'
from urllib.parse import quote
import sys

print(quote(sys.argv[1], safe=""))
PY
)"

endpoint="https://api.indexnow.org/indexnow?url=$encoded_url&key=$key"
key_location="https://www.yolkmeet.com/$(basename "$key_file")"

cat <<EOF
IndexNow readiness dry-run
event=$event
endpoint=$endpoint
key=$key
key_location=$key_location
note=IndexNow submission can notify participating search engines about real publish/update/delete events, but it does not guarantee indexing or ranking.
EOF
