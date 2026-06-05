#!/usr/bin/env bash
set -euo pipefail

DOMAIN="yolkmeet.com"
WEBROOT="/var/www/yolkmeet.com"
SITE_TITLE="Automation Shelf"
ORIGIN_IP="168.107.11.71"
DEPLOY_USER="wpdeploy"
WEB_GROUP="www-data"
DB_NAME="wp_yolkmeet"
DB_USER="wp_yolkmeet"
SECRET_DIR="/etc/yolkmeet-wordpress"
ADMIN_EMAIL="admin@yolkmeet.com"

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "Run with sudo or as root." >&2
    exit 1
  fi
}

rescan_disk() {
  if [ -w /sys/class/block/sda/device/rescan ]; then
    echo 1 > /sys/class/block/sda/device/rescan || true
  fi
  partprobe /dev/sda || true
  local disk_size part_size
  disk_size="$(blockdev --getsize64 /dev/sda 2>/dev/null || echo 0)"
  part_size="$(blockdev --getsize64 /dev/sda1 2>/dev/null || echo 0)"
  if [ "$disk_size" -gt "$part_size" ]; then
    growpart /dev/sda 1 || true
    resize2fs /dev/sda1 || true
  fi
}

install_packages() {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y \
    -o Dpkg::Options::=--force-confdef \
    -o Dpkg::Options::=--force-confold \
    acl certbot cloud-guest-utils curl dnsutils fail2ban mariadb-server nginx parted php-bcmath php-cli php-curl \
    php-fpm php-gd php-imagick php-intl php-mbstring php-mysql php-soap \
    php-xml php-zip python3-certbot-nginx redis-server unattended-upgrades \
    unzip ufw
  apt-get purge -y phpmyadmin || true
  rm -rf /etc/phpmyadmin /usr/share/phpmyadmin
  systemctl enable --now redis-server
  if ! command -v wp >/dev/null 2>&1; then
    curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
      -o /usr/local/bin/wp
    chmod 0755 /usr/local/bin/wp
  fi
}

configure_os_hardening() {
  install -d -m 0755 /etc/ssh/sshd_config.d
  cat >/etc/ssh/sshd_config.d/99-yolkmeet-hardening.conf <<'EOF'
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
EOF
  sshd -t
  systemctl reload ssh || systemctl reload sshd

  systemctl disable --now rpcbind rpcbind.socket || true
  systemctl mask rpcbind rpcbind.socket || true

  remove_legacy_oci_reject_rules
  ufw allow 22/tcp
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw --force enable
  remove_legacy_oci_reject_rules
  ufw reload

  systemctl enable --now fail2ban
  systemctl enable --now redis-server
  dpkg-reconfigure -f noninteractive unattended-upgrades || true
}

remove_legacy_oci_reject_rules() {
  while iptables -C INPUT -j REJECT --reject-with icmp-host-prohibited 2>/dev/null; do
    iptables -D INPUT -j REJECT --reject-with icmp-host-prohibited
  done
  while iptables -C FORWARD -j REJECT --reject-with icmp-host-prohibited 2>/dev/null; do
    iptables -D FORWARD -j REJECT --reject-with icmp-host-prohibited
  done
}

prepare_users_and_secrets() {
  if ! id "$DEPLOY_USER" >/dev/null 2>&1; then
    useradd --system --create-home --shell /bin/bash --gid "$WEB_GROUP" "$DEPLOY_USER"
  fi
  install -d -m 0750 -o root -g root "$SECRET_DIR"
  if [ ! -f "$SECRET_DIR/db-password" ]; then
    openssl rand -base64 36 >"$SECRET_DIR/db-password"
  fi
  if [ ! -f "$SECRET_DIR/admin-password" ]; then
    openssl rand -base64 36 >"$SECRET_DIR/admin-password"
  fi
  chmod 0600 "$SECRET_DIR/db-password" "$SECRET_DIR/admin-password"
}

configure_database() {
  local db_pass
  db_pass="$(cat "$SECRET_DIR/db-password")"
  cat >/etc/mysql/mariadb.conf.d/60-yolkmeet-local.cnf <<'EOF'
[mysqld]
bind-address = 127.0.0.1
skip-name-resolve
EOF
  systemctl enable --now mariadb
  systemctl restart mariadb
  mysql --protocol=socket <<SQL
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_520_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$db_pass';
ALTER USER '$DB_USER'@'localhost' IDENTIFIED BY '$db_pass';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, INDEX, REFERENCES, CREATE TEMPORARY TABLES, LOCK TABLES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
SQL
}

configure_wordpress() {
  local db_pass admin_pass site_url
  db_pass="$(cat "$SECRET_DIR/db-password")"
  admin_pass="$(cat "$SECRET_DIR/admin-password")"
  site_url="$(canonical_url)"
  install -d -m 2775 -o "$DEPLOY_USER" -g "$WEB_GROUP" "$WEBROOT"
  if [ ! -f "$WEBROOT/wp-includes/version.php" ]; then
    sudo -u "$DEPLOY_USER" wp core download --path="$WEBROOT" --skip-content
  fi
  if [ ! -f "$WEBROOT/wp-config.php" ]; then
    printf '%s\n' "$db_pass" | sudo -u "$DEPLOY_USER" wp config create \
      --path="$WEBROOT" \
      --dbname="$DB_NAME" \
      --dbuser="$DB_USER" \
      --dbhost="localhost" \
      --dbcharset="utf8mb4" \
      --dbcollate="utf8mb4_unicode_520_ci" \
      --prompt=dbpass \
      --skip-check
    sudo -u "$DEPLOY_USER" wp config shuffle-salts --path="$WEBROOT"
  else
    sudo -u "$DEPLOY_USER" wp --quiet config set DB_NAME "$DB_NAME" --type=constant --path="$WEBROOT"
    sudo -u "$DEPLOY_USER" wp --quiet config set DB_USER "$DB_USER" --type=constant --path="$WEBROOT"
    set_wp_config_secret DB_PASSWORD "$SECRET_DIR/db-password"
    sudo -u "$DEPLOY_USER" wp --quiet config set DB_HOST "localhost" --type=constant --path="$WEBROOT"
  fi
  if ! sudo -u "$DEPLOY_USER" wp core is-installed --path="$WEBROOT" >/dev/null 2>&1; then
    printf '%s\n' "$admin_pass" | sudo -u "$DEPLOY_USER" wp core install \
      --path="$WEBROOT" \
      --url="$site_url" \
      --title="$SITE_TITLE" \
      --admin_user="siteadmin" \
      --admin_email="$ADMIN_EMAIL" \
      --prompt=admin_password \
      --skip-email
  fi
  sudo -u "$DEPLOY_USER" wp option update home "$site_url" --path="$WEBROOT"
  sudo -u "$DEPLOY_USER" wp option update siteurl "$site_url" --path="$WEBROOT"
  sudo -u "$DEPLOY_USER" wp post delete 1 --force --path="$WEBROOT" >/dev/null 2>&1 || true
  sudo -u "$DEPLOY_USER" wp post delete 2 --force --path="$WEBROOT" >/dev/null 2>&1 || true
  rm -f "$WEBROOT/wp-content/plugins/hello.php"
  find "$WEBROOT" -type d -exec chmod 2750 {} +
  find "$WEBROOT" -type f -exec chmod 0640 {} +
  install -d -m 2770 -o "$DEPLOY_USER" -g "$WEB_GROUP" "$WEBROOT/wp-content/uploads"
  chown -R "$DEPLOY_USER:$WEB_GROUP" "$WEBROOT"
}

configure_nginx() {
  local php_socket
  php_socket="$(find /run/php -maxdepth 1 -name 'php*-fpm.sock' | sort | tail -n 1)"
  cat >/etc/nginx/sites-available/yolkmeet.com <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN;
    root $WEBROOT;
    index index.php index.html;

    client_max_body_size 32m;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:$php_socket;
    }

    location ~* /(wp-config.php|readme.html|license.txt) {
        deny all;
    }

    location ~* ^/phpmyadmin(/|$) {
        return 404;
    }
}
EOF
  ln -sfn /etc/nginx/sites-available/yolkmeet.com /etc/nginx/sites-enabled/yolkmeet.com
  rm -f /etc/nginx/sites-enabled/default
  nginx -t
  systemctl enable --now nginx
  systemctl reload nginx
}

set_wp_config_secret() {
  local constant_name="$1"
  local secret_file="$2"
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
  ' "$WEBROOT/wp-config.php" "$constant_name" "$secret_file"
}

maybe_issue_certificate() {
  local cert_domains
  cert_domains=()
  if domain_points_to_origin "$DOMAIN"; then
    cert_domains+=("-d" "$DOMAIN")
  fi
  if domain_points_to_origin "www.$DOMAIN"; then
    cert_domains+=("-d" "www.$DOMAIN")
  fi
  if [ "${#cert_domains[@]}" -gt 0 ]; then
    certbot --nginx --non-interactive --agree-tos --redirect \
      --email "$ADMIN_EMAIL" "${cert_domains[@]}" || true
  fi
}

domain_points_to_origin() {
  local host="$1"
  {
    getent ahostsv4 "$host" | awk '{print $1}'
    dig +short "$host" A @ns.gabia.co.kr 2>/dev/null || true
    dig +short "$host" A 2>/dev/null || true
  } | grep -Fxq "$ORIGIN_IP"
}

canonical_url() {
  if domain_points_to_origin "$DOMAIN"; then
    printf 'https://%s\n' "$DOMAIN"
  elif domain_points_to_origin "www.$DOMAIN"; then
    printf 'https://www.%s\n' "$DOMAIN"
  else
    printf 'https://%s\n' "$DOMAIN"
  fi
}

verify_runtime() {
  sudo -u "$DEPLOY_USER" wp core version --path="$WEBROOT"
  sudo -u "$DEPLOY_USER" wp option get home --path="$WEBROOT"
  sudo -u "$DEPLOY_USER" wp db check --path="$WEBROOT"
  sudo -u "$DEPLOY_USER" wp plugin list --path="$WEBROOT"
  redis-cli ping
  lsblk -b -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
  df -h /
  ss -ltnp
  ufw status verbose
}

main() {
  require_root
  rescan_disk
  install_packages
  configure_os_hardening
  prepare_users_and_secrets
  configure_database
  configure_wordpress
  configure_nginx
  maybe_issue_certificate
  verify_runtime
}

main "$@"
