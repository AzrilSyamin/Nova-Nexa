run_attachsite() {
    # ══════════════════════════════════════════════════════════════
    #  attach — Attach existing project folder to Nginx + SSL + Hosts
    #
    #  Usage:
    #    attach <n> --cat=<category> [options]
    #
    #  Categories (required):
    #    --cat=dev       ~/projects/dev/<n>     → https://<n>.dev.test
    #    --cat=staging   ~/projects/staging/<n> → https://<n>.staging.test
    #    --cat=study     ~/projects/study/<n>   → https://<n>.study.test
    #
    #  Options:
    #    --php=7.4|8.1|8.2|8.3|8.4   PHP version (default: 8.2)
    #    --js                          JS project (reverse proxy mode)
    #    --port=XXXX                   Dev server port (default: 3000, Vite: 5173)
    #
    #  Examples:
    #    attach myapp --cat=dev
    #    attach myapp --cat=dev --php=8.1
    #    attach myapp --cat=dev --js --port=5173
    #    attach myapp --cat=staging --js --port=3000
    # ══════════════════════════════════════════════════════════════

    local VALID_CATEGORIES="dev staging study"
    local PROJECTS_BASE="$HOME/projects"
    local CERTS_DIR="$HOME/.local/share/mkcert"
    local PENDING_FILE="/mnt/c/wsl-hosts-sync/pending.txt"

# ── Show help ─────────────────────────────────────────────────
if [ -z "$1" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    cat << HELP

attach — Attach existing project folder to Nginx + SSL + Hosts

Usage:
    attach <n> --cat=<category> [options]

Categories (required):
    --cat=dev       ~/projects/dev/<n>     → <n>.dev.test
    --cat=staging   ~/projects/staging/<n> → <n>.staging.test
    --cat=study     ~/projects/study/<n>   → <n>.study.test

Options:
    --php=8.2       PHP version (default: 8.2)
    --js            JS project (uses reverse proxy instead of PHP-FPM)
    --port=XXXX     Dev server port (default: 3000, use 5173 for Vite)

Examples:
    attach myapp --cat=dev
    attach myapp --cat=dev --php=8.1
    attach myapp --cat=dev --js --port=5173
    attach myapp --cat=staging --js --port=3000

HELP
    return 0
fi

    local PROJECT_NAME=$1

    # ── Parse arguments ───────────────────────────────────────────
    local CATEGORY=""
    local PHP_VERSION="8.2"
    local IS_JS=false
    local DEV_PORT="3000"

    for arg in "$@"; do
        case $arg in
            --cat=*)  CATEGORY="${arg#*=}" ;;
            --php=*)  PHP_VERSION="${arg#*=}" ;;
            --js)     IS_JS=true ;;
            --port=*) DEV_PORT="${arg#*=}" ;;
        esac
    done

    # ── Validate category ─────────────────────────────────────────
    if [ -z "$CATEGORY" ]; then
        echo ""
        echo "Error: --cat is required."
        echo "  --cat=dev | --cat=staging | --cat=study"
        echo ""
        echo "Example: attach $PROJECT_NAME --cat=dev"
        return 1
    fi

    if [[ ! " $VALID_CATEGORIES " =~ " $CATEGORY " ]]; then
        echo ""
        echo "Error: Invalid category '$CATEGORY'. Valid: dev, staging, study"
        return 1
    fi

    # ── Resolve paths & domain ────────────────────────────────────
    local PROJECT_DIR="$PROJECTS_BASE/$CATEGORY/$PROJECT_NAME"
    local DOMAIN="${PROJECT_NAME}.${CATEGORY}.test"
    local USER=$(whoami)

    # ── Check folder exists ───────────────────────────────────────
    if [ ! -d "$PROJECT_DIR" ]; then
        echo ""
        echo "Error: Folder not found: $PROJECT_DIR"
        echo ""
        echo "Make sure your project is at the correct path:"
        echo "  ~/projects/$CATEGORY/$PROJECT_NAME"
        return 1
    fi

    # ── Check domain not already configured ──────────────────────
    if [ -f "/etc/nginx/sites-available/${DOMAIN}.conf" ]; then
        echo ""
        echo "Error: Domain '$DOMAIN' is already configured."
        echo "  Config: /etc/nginx/sites-available/${DOMAIN}.conf"
        echo ""
        echo "To remove it first, run: delsite $DOMAIN"
        return 1
    fi

    # ── Detect web root ───────────────────────────────────────────
    # Laravel: has both public/ AND storage/ → use public/ as web root
    # Plain PHP with public/index.php: use public/
    # Everything else: use project root
    local WEB_ROOT="$PROJECT_DIR"
    local IS_LARAVEL=false

    if [ -d "$PROJECT_DIR/public" ] && [ -d "$PROJECT_DIR/storage" ]; then
        IS_LARAVEL=true
        WEB_ROOT="$PROJECT_DIR/public"
    elif [ -d "$PROJECT_DIR/public" ] && [ -f "$PROJECT_DIR/public/index.php" ]; then
        WEB_ROOT="$PROJECT_DIR/public"
    fi

    # ── Summary ───────────────────────────────────────────────────
    echo ""
    echo "════════════════════════════════════════"
    echo "  Attaching : $DOMAIN"
    echo "  Category  : $CATEGORY"
    echo "  Path      : $PROJECT_DIR"
    if [ "$IS_JS" = true ]; then
        echo "  Mode      : JS (reverse proxy → localhost:$DEV_PORT)"
    elif [ "$IS_LARAVEL" = true ]; then
        echo "  Mode      : Laravel (PHP $PHP_VERSION)"
        echo "  Web root  : $WEB_ROOT"
    else
        echo "  Mode      : PHP $PHP_VERSION"
        echo "  Web root  : $WEB_ROOT"
    fi
    echo "════════════════════════════════════════"
    echo ""

    # ── Set permissions ───────────────────────────────────────────
    sudo chown -R $USER:www-data "$PROJECT_DIR"
    sudo chmod -R 775 "$PROJECT_DIR"

    if [ "$IS_LARAVEL" = true ]; then
        chmod -R 775 "$PROJECT_DIR/storage"
        chmod -R 775 "$PROJECT_DIR/bootstrap/cache"
    fi

    # ══════════════════════════════════════════
    #  GENERATE SSL CERTIFICATE
    # ══════════════════════════════════════════
    cd "$CERTS_DIR"
    mkcert "$DOMAIN"

    # ══════════════════════════════════════════
    #  CREATE NGINX CONFIG
    # ══════════════════════════════════════════
if [ "$IS_JS" = true ]; then
    # Reverse proxy → JS dev server
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

else
    # Serve directly → PHP / Laravel
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
fi

    # ── Enable site ───────────────────────────────────────────────
    sudo ln -s /etc/nginx/sites-available/${DOMAIN}.conf /etc/nginx/sites-enabled/

    # ── Test & reload Nginx ───────────────────────────────────────
    sudo nginx -t
    if [ $? -ne 0 ]; then
        echo "Error: Nginx configuration test failed"
        return 1
    fi

    if [ "$IS_JS" = false ]; then
        sudo service php${PHP_VERSION}-fpm start 2>/dev/null
    fi

    sudo service nginx reload

    # ══════════════════════════════════════════
    #  AUTO-UPDATE WINDOWS HOSTS FILE
    # ══════════════════════════════════════════
    if [ -d "/mnt/c/wsl-hosts-sync" ]; then
        if [ -f "$PENDING_FILE" ]; then
            echo "ADD $DOMAIN 127.0.0.1" >> "$PENDING_FILE"
        else
            echo "ADD $DOMAIN 127.0.0.1" > "$PENDING_FILE"
        fi
        HOSTS_MSG="🌐 Hosts file will be updated in ~5 seconds (automatic)"
    else
        HOSTS_MSG="⚠ Add manually: 127.0.0.1 ${DOMAIN}  →  C:\\Windows\\System32\\drivers\\etc\\hosts"
    fi

    # ══════════════════════════════════════════
    #  FINAL SUMMARY
    # ══════════════════════════════════════════
    echo ""
    echo "════════════════════════════════════════"
    echo "  ✓ Site attached successfully!"
    echo "════════════════════════════════════════"
    echo ""
    echo "  URL      : https://${DOMAIN}"
    echo "  Category : $CATEGORY"
    echo "  Path     : ${PROJECT_DIR}"
    echo ""

    if [ "$IS_JS" = true ]; then
        echo "  ⚡ Start your dev server first:"
        echo "     cd ~/projects/$CATEGORY/$PROJECT_NAME"
        echo "     npm run dev -- --host   # Vite (React/Vue)"
        echo "     npm run dev             # Next / Nuxt"
        echo "     node index.js           # Express"
        echo ""
        echo "  Nginx forwards https://${DOMAIN} → localhost:${DEV_PORT}"
        echo ""
    fi

    echo "  $HOSTS_MSG"
    echo ""
}