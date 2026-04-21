#!/bin/bash

# --- Color Definitions ---
BLUE='\033[1;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# ==============================================================================
# NOVA NEXA UTILITIES
# Centralized core functions for Nginx, SSL, and Windows Hosts Sync
# ==============================================================================

# ── 1. Nginx Configuration for JS/Node/Proxy ─────────────────────────────────
# Usage: generate_nginx_js_conf <DOMAIN> <DEV_PORT> <CERTS_DIR>
generate_nginx_js_conf() {
    local DOMAIN=$1
    local DEV_PORT=$2
    local CERTS_DIR=$3

    sudo bash -c "cat > /etc/nginx/sites-available/${DOMAIN}.conf" << EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name ${DOMAIN};

    ssl_certificate     ${CERTS_DIR}/${DOMAIN}.pem;
    ssl_certificate_key ${CERTS_DIR}/${DOMAIN}-key.pem;

    location / {
        proxy_pass http://127.0.0.1:${DEV_PORT};
        proxy_http_version 1.1;

        # WebSocket support (HMR for Vite / Next.js)
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        proxy_read_timeout 86400;
    }
}
EOF

    sudo ln -sf /etc/nginx/sites-available/${DOMAIN}.conf /etc/nginx/sites-enabled/
}

# ── 2. Nginx Configuration for PHP ───────────────────────────────────────────
# Usage: generate_nginx_php_conf <DOMAIN> <WEB_ROOT> <CERTS_DIR> <PHP_VERSION>
generate_nginx_php_conf() {
    local DOMAIN=$1
    local WEB_ROOT=$2
    local CERTS_DIR=$3
    local PHP_VERSION=$4

    sudo bash -c "cat > /etc/nginx/sites-available/${DOMAIN}.conf" << EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name ${DOMAIN};
    root        ${WEB_ROOT};

    index index.php index.html index.htm;

    ssl_certificate     ${CERTS_DIR}/${DOMAIN}.pem;
    ssl_certificate_key ${CERTS_DIR}/${DOMAIN}-key.pem;

    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;

    client_max_body_size 100M;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF

    sudo ln -sf /etc/nginx/sites-available/${DOMAIN}.conf /etc/nginx/sites-enabled/
}

# ── 3. Test and Reload Web Services ─────────────────────────────────────────
# Usage: reload_web_services [PHP_VERSION]
reload_web_services() {
    local PHP_VERSION=$1

    sudo nginx -t
    if [ $? -ne 0 ]; then
        echo -e "\n\033[0;31mError: Nginx configuration test failed\033[0m"
        return 1
    fi

    # Start PHP-FPM if a version was provided
    if [ -n "$PHP_VERSION" ]; then
        sudo service php${PHP_VERSION}-fpm start 2>/dev/null
    fi

    sudo service nginx reload
    return 0
}

# ── 4. Windows Hosts File Synchronization ───────────────────────────────────
# Usage: update_windows_hosts "ADD" <DOMAIN> [IP]  or  "REMOVE" <DOMAIN>
update_windows_hosts() {
    local ACTION=$1
    local DOMAIN=$2
    local IP=${3:-127.0.0.1}
    # Uses NEXA_HOSTS_SYNC_DIR from ~/.config/nexa/config.sh (loaded by main.sh)
    local HOSTS_SYNC_DIR="${NEXA_HOSTS_SYNC_DIR:-/mnt/c/wsl-hosts-sync}"
    local PENDING_FILE="$HOSTS_SYNC_DIR/pending.txt"

    if [ -d "$HOSTS_SYNC_DIR" ]; then
        if [ "$ACTION" = "ADD" ]; then
            if [ -f "$PENDING_FILE" ]; then
                echo "ADD $DOMAIN $IP" >> "$PENDING_FILE"
            else
                echo "ADD $DOMAIN $IP" > "$PENDING_FILE"
            fi
            echo "  🌐 Hosts file will be updated in ~5 seconds (automatic)"
        elif [ "$ACTION" = "REMOVE" ]; then
            if [ -f "$PENDING_FILE" ]; then
                echo "REMOVE $DOMAIN" >> "$PENDING_FILE"
            else
                echo "REMOVE $DOMAIN" > "$PENDING_FILE"
            fi
            echo "  ✓ Hosts file will be updated in ~5 seconds (automatic)"
        fi
    else
        if [ "$ACTION" = "ADD" ]; then
            echo "  ⚠ Add manually: $IP $DOMAIN  →  C:\Windows\System32\drivers\etc\hosts"
        elif [ "$ACTION" = "REMOVE" ]; then
            echo "  ⚠ Windows bridge not found. Remove manually: $DOMAIN from C:\Windows\System32\drivers\etc\hosts"
        fi
    fi
}

# ── 5. Internet Connectivity Check ───────────────────────────────────────────
# Usage: check_internet || return 1
check_internet() {
    if ! curl -sSf --max-time 5 "https://github.com" -o /dev/null 2>/dev/null; then
        echo -e "  ${RED}✗ No internet connection. Please check your network and try again.${NC}"
        return 1
    fi
    return 0
}

# ── 6. UI Helpers ────────────────────────────────────────────────────────────
# Usage: nexa_header "TEXT" [COLOR]
nexa_header() {
    local TEXT=$1
    local COLOR=${2:-$BLUE}
    echo -e "\n${COLOR}══════════════════════════════════════════════════════════════${NC}"
    # Calculate padding for 60 chars width (30 - text/2)
    echo -e "${COLOR}                  $TEXT${NC}"
    echo -e "${COLOR}══════════════════════════════════════════════════════════════${NC}"
}

# Usage: nexa_box "Title" or nexa_box "border"
nexa_box() {
    if [ "$1" = "border" ]; then
        echo "════════════════════════════════════════"
    else
        echo "════════════════════════════════════════"
        echo "  $1"
        echo "════════════════════════════════════════"
    fi
}
