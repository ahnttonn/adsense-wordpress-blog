#!/usr/bin/env bash
set -euo pipefail

DB_NAME="wp_yolkmeet"
WP_ROOT="/var/www/yolkmeet.com"
LOCAL_BACKUP_ROOT="${LOCAL_BACKUP_ROOT:-/var/backups/yolkmeet}"
OFFHOST_DIR="${OFFHOST_DIR:-}"
OFFHOST_SSH_TARGET="${OFFHOST_SSH_TARGET:-}"
OFFHOST_SSH_PORT="${OFFHOST_SSH_PORT:-22}"
ALLOW_LOCAL_ONLY_BACKUP="${ALLOW_LOCAL_ONLY_BACKUP:-0}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_dir="$LOCAL_BACKUP_ROOT/$timestamp"
manifest="$backup_dir/manifest.txt"

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root." >&2
    exit 1
  fi
}

backup_database() {
  local sql_file="$backup_dir/${DB_NAME}.sql.gz"
  if command -v mariadb-dump >/dev/null 2>&1; then
    mariadb-dump --single-transaction --quick --add-drop-table "$DB_NAME" | gzip -9 >"$sql_file"
  else
    mysqldump --single-transaction --quick --add-drop-table "$DB_NAME" | gzip -9 >"$sql_file"
  fi
}

require_offhost_target() {
  if [ -z "$OFFHOST_DIR" ] && [ -z "$OFFHOST_SSH_TARGET" ] && [ "$ALLOW_LOCAL_ONLY_BACKUP" != "1" ]; then
    echo "OFFHOST_DIR must be set or OFFHOST_SSH_TARGET must be set; same-disk-only backups are not allowed." >&2
    exit 1
  fi
  case "$RETENTION_DAYS" in
    ''|*[!0-9]*)
      echo "RETENTION_DAYS must be a non-negative integer." >&2
      exit 1
      ;;
  esac
  case "$OFFHOST_SSH_PORT" in
    ''|*[!0-9]*)
      echo "OFFHOST_SSH_PORT must be a numeric TCP port." >&2
      exit 1
      ;;
  esac
  if [ -n "$OFFHOST_DIR" ]; then
    install -d -m 0750 "$LOCAL_BACKUP_ROOT" "$OFFHOST_DIR"
    local local_device offhost_device
    local_device="$(df -P "$LOCAL_BACKUP_ROOT" | awk 'NR == 2 { print $1 }')"
    offhost_device="$(df -P "$OFFHOST_DIR" | awk 'NR == 2 { print $1 }')"
    if [ "$local_device" = "$offhost_device" ] && [ "$ALLOW_LOCAL_ONLY_BACKUP" != "1" ]; then
      echo "OFFHOST_DIR must be on a different filesystem than LOCAL_BACKUP_ROOT." >&2
      exit 1
    fi
  fi
}

backup_wp_content() {
  tar --directory "$WP_ROOT" -czf "$backup_dir/wp-content.tar.gz" wp-content
}

write_manifest() {
  {
    echo "created_utc=$timestamp"
    echo "db_name=$DB_NAME"
    echo "wp_root=$WP_ROOT"
    echo "siteurl=$(sudo -u wpdeploy wp option get siteurl --path="$WP_ROOT")"
    echo "home=$(sudo -u wpdeploy wp option get home --path="$WP_ROOT")"
    echo "wordpress_core=$(sudo -u wpdeploy wp core version --path="$WP_ROOT")"
    echo "files:"
    find "$backup_dir" -maxdepth 1 -type f -printf "%f %s bytes\n" | sort
  } >"$manifest"
  (cd "$backup_dir" && sha256sum ./*.gz manifest.txt > SHA256SUMS)
}

verify_backup_dir() {
  local verified_dir="$1"
  test -d "$verified_dir"
  test -f "$verified_dir/SHA256SUMS"
  (cd "$verified_dir" && sha256sum -c SHA256SUMS >/dev/null)
}

copy_offhost() {
  if [ -n "$OFFHOST_DIR" ]; then
    install -d -m 0750 "$OFFHOST_DIR"
    rsync -a --delete "$backup_dir/" "$OFFHOST_DIR/$timestamp/"
    verify_backup_dir "$OFFHOST_DIR/$timestamp"
    echo "$OFFHOST_DIR/$timestamp"
  fi
  if [ -n "$OFFHOST_SSH_TARGET" ]; then
    rsync -a -e "ssh -p $OFFHOST_SSH_PORT -o BatchMode=yes -o StrictHostKeyChecking=accept-new" \
      "$backup_dir/" "$OFFHOST_SSH_TARGET/$timestamp/"
    echo "$OFFHOST_SSH_TARGET/$timestamp"
  fi
}

validate_prune_root() {
  case "$LOCAL_BACKUP_ROOT" in
    ''|'/'|'/tmp'|'/tmp/'|'/var'|'/var/'|'/var/backups'|'/var/backups/')
      echo "LOCAL_BACKUP_ROOT is too broad for retention pruning: $LOCAL_BACKUP_ROOT" >&2
      exit 1
      ;;
  esac
}

prune_old_backups() {
  verify_backup_dir "$backup_dir"
  validate_prune_root
  find "$LOCAL_BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -name '20??????T??????Z' ! -path "$backup_dir" -mtime +"$RETENTION_DAYS" -exec rm -rf -- {} +
}

main() {
  require_root
  require_offhost_target
  install -d -m 0750 "$backup_dir"
  backup_database
  backup_wp_content
  write_manifest
  verify_backup_dir "$backup_dir"
  copy_offhost
  prune_old_backups
  echo "$backup_dir"
}

main "$@"
