#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
backup_script="$repo_root/infra/backup-wordpress.sh"
restore_script="$repo_root/infra/restore-rehearsal.sh"
ops_script="$repo_root/infra/configure-ops-hardening.sh"
failures=0

fail() {
  echo "$1" >&2
  failures=$((failures + 1))
}

require_file() {
  local file="$1"
  if [ ! -f "$file" ]; then
    fail "missing file: $file"
    return
  fi
  if [ ! -x "$file" ]; then
    fail "not executable: $file"
  fi
  bash -n "$file" || fail "shell syntax failed: $file"
}

require_pattern() {
  local file="$1"
  local pattern="$2"
  local description="$3"
  local output status
  set +e
  output="$(grep -Eq -- "$pattern" "$file" 2>&1)"
  status=$?
  set -e
  case "$status" in
    0)
      ;;
    1)
      fail "missing required policy in $(basename "$file"): $description"
      ;;
    *)
      fail "grep failed while checking $(basename "$file"): $description"
      if [ -n "$output" ]; then
        printf '%s\n' "$output" >&2
      fi
      ;;
  esac
}

require_order() {
  local file="$1"
  local first_pattern="$2"
  local second_pattern="$3"
  local description="$4"
  local first_line second_line
  first_line="$(first_matching_line "$file" "$first_pattern" "$description first pattern")"
  second_line="$(first_matching_line "$file" "$second_pattern" "$description second pattern")"
  if [ -z "$first_line" ] || [ -z "$second_line" ] || [ "$first_line" -ge "$second_line" ]; then
    fail "invalid policy order in $(basename "$file"): $description"
  fi
}

require_count_at_least() {
  local file="$1"
  local pattern="$2"
  local minimum="$3"
  local description="$4"
  local output status count
  set +e
  output="$(grep -Ec -- "$pattern" "$file" 2>&1)"
  status=$?
  set -e
  case "$status" in
    0|1)
      count="${output:-0}"
      if [ "$count" -lt "$minimum" ]; then
        fail "missing repeated policy in $(basename "$file"): $description"
      fi
      ;;
    *)
      fail "grep failed while checking $(basename "$file"): $description"
      if [ -n "$output" ]; then
        printf '%s\n' "$output" >&2
      fi
      ;;
  esac
}

first_matching_line() {
  local file="$1"
  local pattern="$2"
  local description="$3"
  local output status
  set +e
  output="$(grep -nE -- "$pattern" "$file" 2>&1)"
  status=$?
  set -e
  case "$status" in
    0)
      printf '%s\n' "$output" | head -n 1 | cut -d: -f1
      ;;
    1)
      ;;
    *)
      fail "grep failed while checking $(basename "$file"): $description"
      if [ -n "$output" ]; then
        printf '%s\n' "$output" >&2
      fi
      ;;
  esac
}

forbid_pattern() {
  local file="$1"
  local pattern="$2"
  local description="$3"
  local output status
  set +e
  output="$(grep -Eq -- "$pattern" "$file" 2>&1)"
  status=$?
  set -e
  case "$status" in
    0)
      fail "forbidden policy in $(basename "$file"): $description"
      ;;
    1)
      ;;
    *)
      fail "grep failed while checking $(basename "$file"): $description"
      if [ -n "$output" ]; then
        printf '%s\n' "$output" >&2
      fi
      ;;
  esac
}

require_file "$backup_script"
require_file "$restore_script"
require_file "$ops_script"

if [ -f "$backup_script" ]; then
  require_pattern "$backup_script" 'DB_NAME="wp_yolkmeet"' "uses production DB name"
  require_pattern "$backup_script" 'WP_ROOT="/var/www/yolkmeet.com"' "uses production WordPress path"
  require_pattern "$backup_script" 'mariadb-dump|mysqldump' "dumps database"
  require_pattern "$backup_script" 'tar .*wp-content' "archives wp-content"
  require_pattern "$backup_script" 'sha256sum' "writes checksums"
  require_pattern "$backup_script" 'OFFHOST_DIR' "supports off-host copy target"
  require_pattern "$backup_script" 'OFFHOST_SSH_TARGET' "supports SSH off-host copy target"
  require_pattern "$backup_script" 'same-disk-only backups are not allowed|ALLOW_LOCAL_ONLY_BACKUP' "rejects silent local-only backup runs"
  require_pattern "$backup_script" 'ALLOW_LOCAL_ONLY_BACKUP' "requires explicit local-only override before same-disk backups"
  require_pattern "$backup_script" 'verify_backup_dir "\$backup_dir"' "verifies newest backup before pruning old backups"
  require_order "$backup_script" 'copy_offhost' 'prune_old_backups' "copies off-host before pruning local retention"
  require_pattern "$backup_script" 'rsync -a --delete "\$backup_dir/" "\$OFFHOST_DIR/\$timestamp/"' "quotes local off-host paths with spaces"
  require_pattern "$backup_script" 'find "\$LOCAL_BACKUP_ROOT".*-mtime' "prunes local retention"
  forbid_pattern "$backup_script" 'copy_offhost \|\| true' "must not ignore off-host copy failures"
  forbid_pattern "$backup_script" 'DB_PASSWORD|admin_password|/etc/yolkmeet-wordpress/db-password|/etc/yolkmeet-wordpress/admin-password' "must not read or print WordPress secrets"
fi

if [ -f "$restore_script" ]; then
  require_pattern "$restore_script" 'RESTORE_DB_PREFIX="wp_yolkmeet_restore"' "uses disposable restore DB prefix"
  require_pattern "$restore_script" 'validate_identifier "\$restore_db"' "validates disposable restore DB identifier"
  require_pattern "$restore_script" 'validate_identifier "\$restore_user"' "validates disposable restore DB user identifier"
  require_pattern "$restore_script" 'restore_db" = "wp_yolkmeet"' "rejects production DB name for restore rehearsal"
  require_pattern "$restore_script" '/var/www/yolkmeet.com' "rejects production WordPress path for restore rehearsal"
  require_pattern "$restore_script" 'trap .*cleanup' "cleans disposable restore resources"
  require_pattern "$restore_script" 'mariadb .* <' "imports SQL into disposable DB"
  require_pattern "$restore_script" 'wp option get siteurl' "proves restored DB is readable"
  require_pattern "$restore_script" 'wp core download' "uses disposable WordPress core"
  require_pattern "$restore_script" 'set_wp_config_secret .*DB_PASSWORD' "does not pass restore DB password on WP-CLI argv"
  require_pattern "$restore_script" 'validate_tar_members' "rejects unsafe wp-content archive members"
  require_pattern "$restore_script" 'tar -tzf' "lists archive before extraction"
  require_pattern "$restore_script" 'install -d -m 0750 -o wpdeploy -g www-data "\$restore_dir/public"' "quotes disposable restore path with spaces"
  forbid_pattern "$restore_script" 'wp_yolkmeet;|DROP DATABASE wp_yolkmeet|/var/www/yolkmeet.com/wp-config.php' "must not overwrite production DB/config"
  forbid_pattern "$restore_script" '--prompt=dbpass' "must not echo DB password through WP-CLI prompt reconstruction"
fi

if [ -f "$ops_script" ]; then
  require_pattern "$ops_script" 'fastcgi_cache_path' "defines FastCGI cache path"
  require_pattern "$ops_script" 'skip_cache' "defines cache bypass logic"
  require_pattern "$ops_script" 'wordpress_logged_in|comment_author|wp-postpass' "bypasses logged-in/comment/password cookies"
  require_pattern "$ops_script" 'request_method = POST' "bypasses POST requests"
  require_pattern "$ops_script" 'query_string' "bypasses query-string traffic"
  require_pattern "$ops_script" 'wp-admin|wp-login.php|preview=true' "bypasses admin/login/preview"
  require_pattern "$ops_script" 'fastcgi_cache_methods GET HEAD' "limits FastCGI cacheable methods"
  require_pattern "$ops_script" 'Cache-Control' "sets cache headers"
  require_pattern "$ops_script" 'X-Frame-Options|Content-Security-Policy|X-Content-Type-Options' "sets security headers"
  require_pattern "$ops_script" 'logrotate' "configures log rotation"
  require_pattern "$ops_script" 'fail2ban' "configures fail2ban"
  require_pattern "$ops_script" 'wp-login.php' "protects WordPress login traffic"
  require_pattern "$ops_script" 'yolkmeet-backup.timer' "installs backup timer"
  require_pattern "$ops_script" 'EnvironmentFile=-/etc/yolkmeet-backup.env' "loads backup off-host target env"
  require_pattern "$ops_script" 'yolkmeet-restore-rehearsal' "installs restore rehearsal helper"
  require_pattern "$ops_script" 'nginx -t' "syntax checks Nginx before reload"
  require_pattern "$ops_script" 'server_tokens off' "hides Nginx version tokens"
  require_pattern "$ops_script" 'Strict-Transport-Security' "sets HSTS after HTTPS"
  require_count_at_least "$ops_script" 'add_header X-Content-Type-Options "nosniff" always' 3 "security headers apply in server, PHP cache, and static locations"
  require_count_at_least "$ops_script" 'add_header Strict-Transport-Security' 3 "HSTS applies in server, PHP cache, and static locations"
  require_order "$ops_script" 'wp-config.php\|readme.html\|license.txt' 'location ~ \\\\.php|location ~ \\.php' "denies sensitive files before PHP handler"
  forbid_pattern "$ops_script" 'proxy_cache_valid .*wp-admin|fastcgi_cache_valid .*wp-admin' "must not cache admin"
fi

if [ "$failures" -ne 0 ]; then
  echo "ops hardening policy checks failed: $failures" >&2
  exit 1
fi

echo "ops hardening policy checks passed"
