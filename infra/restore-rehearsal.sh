#!/usr/bin/env bash
set -euo pipefail

RESTORE_DB_PREFIX="wp_yolkmeet_restore"
BACKUP_DIR="${1:-}"
WORK_ROOT="${WORK_ROOT:-/tmp/yolkmeet-restore}"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
restore_db="${RESTORE_DB_PREFIX}_${timestamp}"
restore_user="${restore_db}_user"
restore_dir="$WORK_ROOT/$timestamp"
restore_pass_file="$restore_dir/db-password"
keep_restore="${KEEP_RESTORE:-0}"

usage() {
  echo "Usage: sudo $0 /var/backups/yolkmeet/<timestamp>" >&2
}

cleanup() {
  if [ "$keep_restore" != "1" ]; then
    mariadb --protocol=socket -e "DROP DATABASE IF EXISTS \`$restore_db\`; DROP USER IF EXISTS '$restore_user'@'localhost'; FLUSH PRIVILEGES;" || true
    case "$restore_dir" in
      ''|'/'|/var/www/yolkmeet.com|/var/www/yolkmeet.com/*)
        echo "Refusing to remove unsafe restore path: $restore_dir" >&2
        ;;
      *)
        rm -rf -- "$restore_dir"
        ;;
    esac
  fi
}

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root." >&2
    exit 1
  fi
}

validate_backup() {
  if [ -z "$BACKUP_DIR" ] || [ ! -d "$BACKUP_DIR" ]; then
    usage
    exit 1
  fi
  test -f "$BACKUP_DIR/wp_yolkmeet.sql.gz"
  test -f "$BACKUP_DIR/wp-content.tar.gz"
  test -f "$BACKUP_DIR/SHA256SUMS"
  (cd "$BACKUP_DIR" && sha256sum -c SHA256SUMS)
  validate_tar_members "$BACKUP_DIR/wp-content.tar.gz"
}

validate_tar_members() {
  local archive="$1"
  local member
  while IFS= read -r member; do
    case "$member" in
      wp-content|wp-content/*) ;;
      *)
        echo "Unsafe wp-content archive member: $member" >&2
        exit 1
        ;;
    esac
    case "$member" in
      /*|../*|*/../*|*/..)
        echo "Unsafe wp-content archive member: $member" >&2
        exit 1
        ;;
    esac
  done < <(tar -tzf "$archive")
}

validate_identifier() {
  local identifier="$1"
  case "$identifier" in
    ""|[0-9]*|*[!A-Za-z0-9_]*)
      echo "Unsafe database identifier: $identifier" >&2
      exit 1
      ;;
  esac
  if [ "${#identifier}" -gt 64 ]; then
    echo "Database identifier is too long: $identifier" >&2
    exit 1
  fi
}

validate_restore_targets() {
  validate_identifier "$restore_db"
  validate_identifier "$restore_user"
  if [ "$restore_db" = "wp_yolkmeet" ] || [ "$restore_user" = "wp_yolkmeet" ]; then
    echo "Refusing to restore into production database." >&2
    exit 1
  fi
  case "$restore_dir" in
    /var/www/yolkmeet.com|/var/www/yolkmeet.com/*)
      echo "Refusing to restore into production WordPress path /var/www/yolkmeet.com." >&2
      exit 1
      ;;
  esac
}

create_disposable_database() {
  install -d -m 0750 -o wpdeploy -g www-data "$restore_dir"
  openssl rand -base64 36 >"$restore_pass_file"
  chmod 0600 "$restore_pass_file"
  local restore_pass
  restore_pass="$(cat "$restore_pass_file")"
  mariadb --protocol=socket <<SQL
CREATE DATABASE \`$restore_db\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_520_ci;
CREATE USER '$restore_user'@'localhost' IDENTIFIED BY '$restore_pass';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, INDEX, REFERENCES, CREATE TEMPORARY TABLES, LOCK TABLES ON \`$restore_db\`.* TO '$restore_user'@'localhost';
FLUSH PRIVILEGES;
SQL
  gzip -dc "$BACKUP_DIR/wp_yolkmeet.sql.gz" | mariadb --protocol=socket "$restore_db"
}

create_disposable_wordpress() {
  install -d -m 0750 -o wpdeploy -g www-data "$restore_dir/public"
  sudo -u wpdeploy wp core download --path="$restore_dir/public" --skip-content
  tar --directory "$restore_dir/public" -xzf "$BACKUP_DIR/wp-content.tar.gz"
  chown -R wpdeploy:www-data "$restore_dir/public"
  sudo -u wpdeploy wp --quiet config create \
    --path="$restore_dir/public" \
    --dbname="$restore_db" \
    --dbuser="$restore_user" \
    --dbpass="restore-placeholder" \
    --dbhost="localhost" \
    --dbcharset="utf8mb4" \
    --dbcollate="utf8mb4_unicode_520_ci" \
    --skip-check
  set_wp_config_secret "$restore_dir/public/wp-config.php" DB_PASSWORD "$restore_pass_file"
}

set_wp_config_secret() {
  local config_path="$1"
  local constant_name="$2"
  local secret_file="$3"
  php -r '
    $configPath = $argv[1];
    $constantName = $argv[2];
    $secretFile = $argv[3];
    $value = rtrim(file_get_contents($secretFile));
    $escaped = str_replace(["\\", "'\''"], ["\\\\", "\\'\''"], $value);
    $pattern = "/define\\(\\s*'\''" . preg_quote($constantName, "/") . "'\''\\s*,\\s*'\''[^'\'']*'\''\\s*\\);/";
    $replacement = "define( '\''" . $constantName . "'\'', '\''" . $escaped . "'\'' );";
    $config = file_get_contents($configPath);
    $updated = preg_replace($pattern, $replacement, $config, 1, $count);
    if ($count !== 1) {
      fwrite(STDERR, "missing config constant\n");
      exit(1);
    }
    file_put_contents($configPath, $updated);
  ' "$config_path" "$constant_name" "$secret_file"
}

verify_restore() {
  sudo -u wpdeploy wp option get siteurl --path="$restore_dir/public"
  sudo -u wpdeploy wp option get home --path="$restore_dir/public"
  sudo -u wpdeploy wp db check --path="$restore_dir/public"
}

main() {
  require_root
  validate_restore_targets
  validate_backup
  trap cleanup EXIT
  create_disposable_database
  create_disposable_wordpress
  verify_restore
  echo "restore_rehearsal_ok=$restore_db"
}

main "$@"
