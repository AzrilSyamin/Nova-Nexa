run_newsite() {
    # ══════════════════════════════════════════════════════════════
    #  new — Create a new PHP or JS project with SSL + Nginx + Hosts
    #
    #  Usage:
    #    new <name> --cat=<category> [options]
    #
    #  Categories (required):
    #    --cat=dev       ~/projects/dev/<name>     → https://<name>.dev.test
    #    --cat=staging   ~/projects/staging/<name> → https://<name>.staging.test
    #    --cat=study     ~/projects/study/<name>   → https://<name>.study.test
    #
    #  PHP options:
    #    (no flag)            Plain PHP project
    #    --laravel            Latest Laravel
    #    --laravel=9|10|11|12 Specific Laravel version
    #    --php=7.4|8.1|8.2|8.3|8.4
    #
    #  JS options:
    #    --react    React + Vite   (port 5173)
    #    --next     Next.js        (port 3000)
    #    --vue      Vue + Vite     (port 5173)
    #    --nuxt     Nuxt.js        (port 3000)
    #    --express  Express.js     (port 3000)
    #    --port=XXXX  Override dev port
    #
    #  Examples:
    #    new myapp --cat=dev --laravel=11
    #    new myapp --cat=study --react
    #    new myapp --cat=staging --next --port=3001
    # ══════════════════════════════════════════════════════════════

    local VALID_CATEGORIES="dev staging study"
    local PROJECTS_BASE="$HOME/projects"
    local CERTS_DIR="$HOME/.local/share/mkcert"
    local PENDING_FILE="/mnt/c/wsl-hosts-sync/pending.txt"

    # ── Show help ─────────────────────────────────────────────────
    if [ -z "$1" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        echo ""
        echo "Usage: new <name> --cat=<category> [options]"
        echo ""
        echo "── Categories (required) ────────────────────────────"
        echo "  --cat=dev        ~/projects/dev/<name>     → <name>.dev.test"
        echo "  --cat=staging    ~/projects/staging/<name> → <name>.staging.test"
        echo "  --cat=study      ~/projects/study/<name>   → <name>.study.test"
        echo ""
        echo "── PHP ──────────────────────────────────────────────"
        echo "  (no flag)        Plain PHP"
        echo "  --laravel        Latest Laravel"
        echo "  --laravel=11     Specific version"
        echo "  --php=8.2        PHP version (default: 8.2)"
        echo ""
        echo "── JavaScript ───────────────────────────────────────"
        echo "  --react          React + Vite  (port 5173)"
        echo "  --next           Next.js        (port 3000)"
        echo "  --vue            Vue + Vite     (port 5173)"
        echo "  --nuxt           Nuxt.js        (port 3000)"
        echo "  --express        Express.js     (port 3000)"
        echo "  --port=XXXX      Override dev port"
        echo ""
        echo "── Examples ─────────────────────────────────────────"
        echo "  new myapp --cat=dev --laravel=11 --php=8.3"
        echo "  new myapp --cat=study --react"
        echo "  new myapp --cat=staging --next --port=3001"
        echo "  new myapp --cat=dev --express"
        echo ""
        return 0
    fi

    # ── Validate basic input ──────────────────────────────────────
    if [ -z "$1" ] || [[ "$1" == --* ]]; then
        echo -e "\n${RED}Error: Project name is required and cannot start with '--'${NC}"
        echo "Usage: new <name> --cat=<category> [options]"
        echo "Example: new myapp --cat=dev"
        return 1
    fi

    local PROJECT_NAME=$1

    # ── Parse arguments ───────────────────────────────────────────
    local CATEGORY=""
    local LARAVEL=false
    local LARAVEL_VERSION=""
    local PHP_VERSION="8.2"
    local JS_FRAMEWORK=""
    local DEV_PORT=""

    for arg in "$@"; do
        case $arg in
            --cat=*)         CATEGORY="${arg#*=}" ;;
            --laravel)       LARAVEL=true ;;
            --laravel=*)     LARAVEL=true; LARAVEL_VERSION="${arg#*=}" ;;
            --php=*)         PHP_VERSION="${arg#*=}" ;;
            --react)         JS_FRAMEWORK="react" ;;
            --next)          JS_FRAMEWORK="next" ;;
            --vue)           JS_FRAMEWORK="vue" ;;
            --nuxt)          JS_FRAMEWORK="nuxt" ;;
            --express)       JS_FRAMEWORK="express" ;;
            --port=*)        DEV_PORT="${arg#*=}" ;;
        esac
    done

    # ── Validate category ─────────────────────────────────────────
    if [ -z "$CATEGORY" ]; then
        echo ""
        echo "Error: --cat is required."
        echo ""
        echo "  --cat=dev      Active development"
        echo "  --cat=staging  Staging / pre-production"
        echo "  --cat=study    Learning & experiments"
        echo ""
        echo "Example: new $PROJECT_NAME --cat=dev"
        return 1
    fi

    if [[ ! " $VALID_CATEGORIES " =~ " $CATEGORY " ]]; then
        echo ""
        echo "Error: Invalid category '$CATEGORY'."
        echo "Valid options: dev, staging, study"
        return 1
    fi

    # ── Resolve paths & domain ────────────────────────────────────
    local PROJECT_DIR="$PROJECTS_BASE/$CATEGORY/$PROJECT_NAME"
    local DOMAIN="${PROJECT_NAME}.${CATEGORY}.test"
    local USER=$(whoami)

    # ── Set default dev port ──────────────────────────────────────
    if [ -n "$JS_FRAMEWORK" ] && [ -z "$DEV_PORT" ]; then
        case $JS_FRAMEWORK in
            react|vue)         DEV_PORT=5173 ;;
            next|nuxt|express) DEV_PORT=3000 ;;
        esac
    fi

    # ── Check project doesn't already exist ──────────────────────
    if [ -d "$PROJECT_DIR" ]; then
        echo ""
        echo "Error: Project '$PROJECT_NAME' already exists at $PROJECT_DIR"
        return 1
    fi

    # ── Ensure category directory exists ─────────────────────────
    mkdir -p "$PROJECTS_BASE/$CATEGORY"

    # ── Summary ───────────────────────────────────────────────────
    echo ""
    echo "════════════════════════════════════════"
    echo "  Creating : $DOMAIN"
    echo "  Category : $CATEGORY"
    echo "  Path     : $PROJECT_DIR"
    if [ -n "$JS_FRAMEWORK" ]; then
        echo "  Framework: $JS_FRAMEWORK"
        echo "  Dev port : $DEV_PORT"
    else
        echo "  PHP      : $PHP_VERSION"
        if [ "$LARAVEL" = true ]; then
            [ -n "$LARAVEL_VERSION" ] && echo "  Laravel  : ${LARAVEL_VERSION}.x" || echo "  Laravel  : latest"
        else
            echo "  Type     : Plain PHP"
        fi
    fi
    echo "════════════════════════════════════════"
    echo ""

# ══════════════════════════════════════════
#  CREATE PROJECT
# ══════════════════════════════════════════

if [ -n "$JS_FRAMEWORK" ]; then

    cd "$PROJECTS_BASE/$CATEGORY"

    case $JS_FRAMEWORK in
        react)
            echo "Creating React + Vite project..."
            npm create vite@latest $PROJECT_NAME -- --template react
            ;;
        next)
            echo "Creating Next.js project..."
            npx create-next-app@latest $PROJECT_NAME --yes
            ;;
        vue)
            echo "Creating Vue + Vite project..."
            npm create vite@latest $PROJECT_NAME -- --template vue
            ;;
        nuxt)
            echo "Creating Nuxt.js project..."
            npx nuxi@latest init $PROJECT_NAME
            ;;
        express)
            echo "Creating Express.js project..."
            mkdir -p $PROJECT_NAME && cd $PROJECT_NAME
            npm init -y
            npm install express
            cat > index.js << 'EXPRESSEOF'
const express = require('express')
const app = express()
const port = process.env.PORT || 3000

app.use(express.json())

app.get('/', (req, res) => {
  res.json({
    message: 'Express server is running!',
    domain: process.env.DOMAIN || 'localhost'
  })
})

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`)
})
EXPRESSEOF
            cd ..
            ;;
    esac

    if [ $? -ne 0 ]; then
        echo "Error: Failed to create $JS_FRAMEWORK project"
        return 1
    fi

    if [ "$JS_FRAMEWORK" != "express" ]; then
        cd "$PROJECT_DIR" && npm install
    fi

    local WEB_ROOT="$PROJECT_DIR"

    elif [ "$LARAVEL" = true ]; then

        cd "$PROJECTS_BASE/$CATEGORY"
        if [ -n "$LARAVEL_VERSION" ]; then
            composer create-project laravel/laravel:^$LARAVEL_VERSION $PROJECT_NAME
        else
            composer create-project laravel/laravel $PROJECT_NAME
        fi

        if [ $? -ne 0 ]; then
            echo "Error: Failed to create Laravel project"
            return 1
        fi

        local WEB_ROOT="$PROJECT_DIR/public"

    else

        mkdir -p "$PROJECT_DIR"
        echo "<?php phpinfo();" > "$PROJECT_DIR/index.php"
        local WEB_ROOT="$PROJECT_DIR"

    fi

    # ── Set permissions ───────────────────────────────────────────
    sudo chown -R $USER:www-data "$PROJECT_DIR"
    sudo chmod -R 775 "$PROJECT_DIR"

    if [ "$LARAVEL" = true ]; then
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

if [ -n "$JS_FRAMEWORK" ]; then
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
    # Serve directly → PHP
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

    if [ -z "$JS_FRAMEWORK" ]; then
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
    echo "  ✓ Project created successfully!"
    echo "════════════════════════════════════════"
    echo ""
    echo "  URL      : https://${DOMAIN}"
    echo "  Category : $CATEGORY"
    echo "  Path     : ${PROJECT_DIR}"
    echo ""

    if [ -n "$JS_FRAMEWORK" ]; then
        echo "  ⚡ Start your dev server first:"
        echo ""
        case $JS_FRAMEWORK in
            react|vue)
                echo "     cd ~/projects/$CATEGORY/$PROJECT_NAME"
                echo "     npm run dev -- --host"
                ;;
            next|nuxt)
                echo "     cd ~/projects/$CATEGORY/$PROJECT_NAME"
                echo "     npm run dev"
                ;;
            express)
                echo "     cd ~/projects/$CATEGORY/$PROJECT_NAME"
                echo "     node index.js"
                ;;
        esac
        echo ""
        echo "  Nginx forwards https://${DOMAIN} → localhost:${DEV_PORT}"
        echo ""
    fi

    echo "  $HOSTS_MSG"
    echo ""
}