#!/usr/bin/env bash
set -euo pipefail

DOMAIN="yolkmeet.com"
WEBROOT="/var/www/yolkmeet.com"
REPO_BACKUP_SCRIPT="${REPO_BACKUP_SCRIPT:-/tmp/backup-wordpress.sh}"
REPO_RESTORE_SCRIPT="${REPO_RESTORE_SCRIPT:-/tmp/restore-rehearsal.sh}"

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root." >&2
    exit 1
  fi
}

install_backup_script() {
  install -m 0750 -o root -g root "$REPO_BACKUP_SCRIPT" /usr/local/sbin/yolkmeet-backup
  if [ -f "$REPO_RESTORE_SCRIPT" ]; then
    install -m 0750 -o root -g root "$REPO_RESTORE_SCRIPT" /usr/local/sbin/yolkmeet-restore-rehearsal
  fi
  if [ ! -f /etc/yolkmeet-backup.env ]; then
    cat >/etc/yolkmeet-backup.env <<'EOF'
# Configure one off-host target before relying on the timer.
# OFFHOST_DIR=/mnt/yolkmeet-offhost
# OFFHOST_SSH_TARGET=backup-user@backup-host:/backups/yolkmeet
# OFFHOST_SSH_PORT=22
EOF
    chmod 0640 /etc/yolkmeet-backup.env
  fi
  cat >/etc/systemd/system/yolkmeet-backup.service <<'EOF'
[Unit]
Description=Yolkmeet WordPress backup
Wants=network-online.target
After=network-online.target mariadb.service

[Service]
Type=oneshot
EnvironmentFile=-/etc/yolkmeet-backup.env
ExecStart=/usr/local/sbin/yolkmeet-backup
EOF
  cat >/etc/systemd/system/yolkmeet-backup.timer <<'EOF'
[Unit]
Description=Run Yolkmeet WordPress backup daily

[Timer]
OnCalendar=*-*-* 03:17:00 UTC
RandomizedDelaySec=900
Persistent=true

[Install]
WantedBy=timers.target
EOF
  systemctl daemon-reload
  systemctl enable --now yolkmeet-backup.timer
}

write_logrotate_policy() {
  cat >/etc/logrotate.d/yolkmeet-wordpress <<'EOF'
/var/log/nginx/yolkmeet-access.log /var/log/nginx/yolkmeet-error.log {
    daily
    rotate 14
    missingok
    notifempty
    compress
    delaycompress
    create 0640 www-data adm
    sharedscripts
    postrotate
        systemctl reload nginx >/dev/null 2>&1 || true
    endscript
}
EOF
}

write_fail2ban_policy() {
  cat >/etc/fail2ban/filter.d/yolkmeet-wordpress-login.conf <<'EOF'
[Definition]
failregex = ^<HOST> - .* "(GET|POST) /wp-login\.php(?:\?.*)? HTTP/.*" (?:200|401|403|404)
            ^<HOST> - .* "(GET|POST) /xmlrpc\.php(?:\?.*)? HTTP/.*" (?:200|401|403|404)
ignoreregex =
EOF

  cat >/etc/fail2ban/jail.d/yolkmeet-wordpress.conf <<'EOF'
[yolkmeet-wordpress-login]
enabled = true
filter = yolkmeet-wordpress-login
logpath = /var/log/nginx/yolkmeet-access.log
port = http,https
maxretry = 10
findtime = 600
bantime = 3600
EOF
  systemctl enable --now fail2ban
  fail2ban-client reload || systemctl restart fail2ban
}

write_nginx_cache_policy() {
  cat >/etc/nginx/conf.d/yolkmeet-cache.conf <<'EOF'
server_tokens off;
fastcgi_cache_path /var/cache/nginx/yolkmeet levels=1:2 keys_zone=yolkmeet_fastcgi:128m inactive=60m max_size=1024m use_temp_path=off;
fastcgi_cache_key "$scheme$request_method$host$request_uri";
fastcgi_cache_use_stale error timeout invalid_header http_500 http_503;
fastcgi_cache_lock on;
EOF

  cat >/etc/nginx/sites-available/yolkmeet.com <<EOF
map \$http_cookie \$skip_cache_cookie {
    default 0;
    ~*wordpress_logged_in 1;
    ~*comment_author 1;
    ~*wp-postpass 1;
}

map \$request_uri \$skip_cache_uri {
    default 0;
    ~*wp-admin 1;
    ~*wp-login.php 1;
    ~*wp-json 1;
    ~*preview=true 1;
    ~*\\?preview= 1;
    ~*/feed/ 1;
}

server {
    server_name $DOMAIN www.$DOMAIN;
    root $WEBROOT;
    index index.php index.html;
    access_log /var/log/nginx/yolkmeet-access.log;
    error_log /var/log/nginx/yolkmeet-error.log;

    client_max_body_size 32m;
    set \$skip_cache 0;
    if (\$request_method = POST) { set \$skip_cache 1; }
    if (\$query_string != "") { set \$skip_cache 1; }
    if (\$skip_cache_cookie = 1) { set \$skip_cache 1; }
    if (\$skip_cache_uri = 1) { set \$skip_cache 1; }

    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "upgrade-insecure-requests" always;
    add_header Strict-Transport-Security "max-age=15552000; includeSubDomains" always;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~* /(wp-config.php|readme.html|license.txt) {
        deny all;
    }

    location ~* \\.(?:css|js|jpg|jpeg|gif|png|webp|avif|svg|ico|woff|woff2)$ {
        expires 30d;
        add_header X-Content-Type-Options "nosniff" always;
        add_header Strict-Transport-Security "max-age=15552000; includeSubDomains" always;
        add_header Cache-Control "public, max-age=2592000, immutable" always;
        try_files \$uri =404;
    }

    location ~ \\.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_cache yolkmeet_fastcgi;
        fastcgi_cache_methods GET HEAD;
        fastcgi_cache_valid 200 301 302 10m;
        fastcgi_cache_bypass \$skip_cache;
        fastcgi_no_cache \$skip_cache;
        add_header X-Content-Type-Options "nosniff" always;
        add_header Strict-Transport-Security "max-age=15552000; includeSubDomains" always;
        add_header X-FastCGI-Cache \$upstream_cache_status always;
    }

    location ~* ^/phpmyadmin(/|$) {
        return 404;
    }

    listen [::]:443 ssl ipv6only=on;
    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/www.yolkmeet.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/www.yolkmeet.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}

server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://\$host\$request_uri;
}
EOF
  install -d -m 0750 -o www-data -g www-data /var/cache/nginx/yolkmeet
  nginx -t
  systemctl reload nginx
}

configure_malware_integrity_baseline() {
  install -d -m 0750 /var/lib/yolkmeet-integrity
  find "$WEBROOT" -xdev -type f \
    ! -path "$WEBROOT/wp-content/uploads/*" \
    ! -path "$WEBROOT/wp-content/cache/*" \
    -print0 | sort -z | xargs -0 sha256sum > /var/lib/yolkmeet-integrity/wordpress.sha256
}

main() {
  require_root
  apt-get update
  apt-get install -y fail2ban logrotate rsync
  install_backup_script
  write_logrotate_policy
  write_fail2ban_policy
  write_nginx_cache_policy
  configure_malware_integrity_baseline
  logrotate -d /etc/logrotate.d/yolkmeet-wordpress >/dev/null
  systemctl list-timers yolkmeet-backup.timer --no-pager
}

main "$@"
