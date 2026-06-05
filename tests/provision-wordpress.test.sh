#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$script_dir/infra/provision-wordpress.sh"

test -f "$script"
test -x "$script"

failures=0

fail() {
  echo "$1" >&2
  failures=$((failures + 1))
}

require_pattern() {
  local pattern="$1"
  local description="$2"
  if ! grep -Eq "$pattern" "$script"; then
    fail "missing required policy: $description"
  fi
}

forbid_pattern() {
  local pattern="$1"
  local description="$2"
  if grep -Eq -- "$pattern" "$script"; then
    fail "forbidden policy found: $description"
  fi
}

require_order() {
  local first="$1"
  local second="$2"
  local description="$3"
  local first_line second_line
  first_line="$(grep -nE "$first" "$script" | head -n 1 | cut -d: -f1 || true)"
  second_line="$(grep -nE "$second" "$script" | head -n 1 | cut -d: -f1 || true)"
  if [ -z "$first_line" ] || [ -z "$second_line" ] || [ "$first_line" -ge "$second_line" ]; then
    fail "missing required order: $description"
  fi
}

grep -q 'DOMAIN="yolkmeet.com"' "$script"
grep -q 'WEBROOT="/var/www/yolkmeet.com"' "$script"
grep -q 'DB_NAME="wp_yolkmeet"' "$script"
grep -q 'ufw --force enable' "$script"
grep -q 'remove_legacy_oci_reject_rules' "$script"
grep -q 'iptables -D INPUT -j REJECT --reject-with icmp-host-prohibited' "$script"
grep -q 'iptables -D FORWARD -j REJECT --reject-with icmp-host-prohibited' "$script"
grep -q 'systemctl disable --now rpcbind' "$script"
grep -q 'PasswordAuthentication no' "$script"
grep -q 'wp core install' "$script"
grep -q 'wp db check' "$script"
grep -q 'certbot --nginx' "$script"
grep -q 'return 404;' "$script"

forbid_pattern '--dbpass="\$db_pass"|--dbpass=\$db_pass' "database password passed on WP-CLI argv"
forbid_pattern '--admin_password="\$admin_pass"|--admin_password=\$admin_pass' "WordPress admin password passed on WP-CLI argv"
forbid_pattern 'DB_PASSWORD "\$db_pass"|DB_PASSWORD \$db_pass' "database password updated on WP-CLI argv"
forbid_pattern 'location = /phpmyadmin' "exact-only phpMyAdmin block misses slash and nested paths"
require_pattern 'location ~\* \^/phpmyadmin\(/|\$\)' "phpMyAdmin path family blocked"
require_pattern 'nginx -t' "Nginx configuration syntax checked before reload"
require_order 'nginx -t' 'systemctl reload nginx' "Nginx syntax check runs before reload"
require_pattern '^main\(\)' "main function declared"
require_pattern '^main "\$@"' "main entry point invokes provisioning flow"
require_pattern '^[[:space:]]+configure_nginx$' "main calls Nginx configuration step"
require_pattern '^[[:space:]]+verify_runtime$' "main calls runtime verification step"
require_pattern 'cloud-guest-utils' "disk growpart package installed"
require_pattern 'parted' "disk partprobe package installed"
require_pattern 'curl' "WP-CLI download dependency installed"
require_pattern 'growpart /dev/sda 1' "root partition expansion attempted"
require_pattern 'resize2fs /dev/sda1' "root filesystem expansion attempted"
require_pattern 'nginx' "Nginx package installed"
require_pattern 'php-fpm' "PHP-FPM package installed"
require_pattern 'mariadb-server' "MariaDB package installed"
require_pattern 'redis-server' "Redis package installed"
require_pattern 'systemctl enable --now redis-server' "Redis enabled and started"
require_pattern 'fail2ban' "fail2ban installed and enabled"
require_pattern 'unattended-upgrades' "unattended upgrades installed"
require_pattern 'ufw allow 443/tcp' "HTTPS allowed through UFW"
require_pattern 'apt-get purge -y phpmyadmin' "phpMyAdmin actively purged"
require_pattern 'CREATE USER IF NOT EXISTS '\''\$DB_USER'\''@'\''localhost'\''' "database user limited to localhost"
require_pattern 'GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, INDEX, REFERENCES, CREATE TEMPORARY TABLES, LOCK TABLES' "least-privilege WordPress grants"
require_pattern 'find "\$WEBROOT" -type d -exec chmod 2750' "directory permissions locked down"
require_pattern 'find "\$WEBROOT" -type f -exec chmod 0640' "file permissions locked down"
require_pattern 'install -d -m 2770 .*"\$WEBROOT/wp-content/uploads"' "uploads directory remains group-writable"
require_pattern 'wp core version' "WP-CLI runtime verification"
require_pattern 'redis-cli ping' "Redis runtime verification"
require_pattern 'ss -ltnp' "listening service verification"
require_pattern 'ufw status verbose' "firewall verification"

if grep -Eq '(DB_PASS=|ADMIN_PASS=).*[^$]\w{12,}' "$script"; then
  fail "static credential-looking assignment found"
fi

if grep -Eq 'PermitRootLogin yes|PasswordAuthentication yes|phpmyadmin' "$script" &&
  grep -Eq 'apt-get install.*phpmyadmin|apt install.*phpmyadmin' "$script"; then
  fail "forbidden package install found"
fi

if grep -Eq 'PermitRootLogin yes|PasswordAuthentication yes|GRANT ALL|ALL PRIVILEGES' "$script"; then
  fail "forbidden exposure or SSH setting found"
fi

if [ "$(grep -c '^remove_legacy_oci_reject_rules()' "$script")" -ne 1 ]; then
  fail "legacy OCI reject-rule helper must be defined exactly once"
fi

if [ "$failures" -ne 0 ]; then
  echo "provision-wordpress script policy checks failed: $failures" >&2
  exit 1
fi

echo "provision-wordpress script policy checks passed"
