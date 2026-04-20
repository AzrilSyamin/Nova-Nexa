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

# ── Show help ─────────────────────────────────────────────────
if [ -z "$1" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        echo -e "\n${BLUE}══════════════════════════════════════════════════════════════${NC}"
        echo -e "${BLUE}                 NOVA NEXA - ATTACH SITE                      ${NC}"
        echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
        echo -e "\nUsage: ${YELLOW}attach${NC} <name> --cat=<category> [options]\n"

        echo -e "${YELLOW}Categories (required):${NC}"
        printf "  ${GREEN}%-15s${NC} %-40s\n" "--cat=dev" "~/projects/dev/<name>     → <name>.dev.test"
        printf "  ${YELLOW}%-15s${NC} %-40s\n" "--cat=staging" "~/projects/staging/<name> → <name>.staging.test"
        printf "  ${BLUE}%-15s${NC} %-40s\n" "--cat=study" "~/projects/study/<name>   → <name>.study.test"

        echo -e "\n${YELLOW}Options:${NC}"
        printf "  ${CYAN}%-15s${NC} %-40s\n" "--php=8.2" "Specify PHP version (default: 8.2)"
        printf "  ${CYAN}%-15s${NC} %-40s\n" "--js" "JS project (uses reverse proxy instead of PHP-FPM)"
        printf "  ${WHITE}%-15s${NC} %-40s\n" "--port=XXXX" "Dev server port (default: 3000, Vite: 5173)"

        echo -e "\n${CYAN}Examples:${NC}"
        echo -e "  nexa > ${YELLOW}attach myapp --cat=dev${NC}"
        echo -e "  nexa > ${YELLOW}attach myapp --cat=dev --php=8.1${NC}"
        echo -e "  nexa > ${YELLOW}attach myapp --cat=dev --js --port=5173${NC}"
        echo -e "  nexa > ${YELLOW}attach myapp --cat=staging --js --port=3000${NC}"
        echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}\n"
    return 0
fi

    # ── Validate basic input ──────────────────────────────────────
    if [ -z "$1" ] || [[ "$1" == --* ]]; then
        echo -e "\n${RED}Error: Project name is required and cannot start with '--'${NC}"
        echo "Usage: attach <name> --cat=<category> [options]"
        echo "Example: attach myapp --cat=dev"
        return 1
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
    #  CREATE NGINX CONFIG & RELOAD SERVICES
    # ══════════════════════════════════════════
    if [ "$IS_JS" = true ]; then
        generate_nginx_js_conf "$DOMAIN" "$DEV_PORT" "$CERTS_DIR"
        reload_web_services "" || return 1
    else
        generate_nginx_php_conf "$DOMAIN" "$WEB_ROOT" "$CERTS_DIR" "$PHP_VERSION"
        reload_web_services "$PHP_VERSION" || return 1
    fi

    # ══════════════════════════════════════════
    #  AUTO-UPDATE WINDOWS HOSTS FILE
    # ══════════════════════════════════════════
    HOSTS_MSG=$(update_windows_hosts "ADD" "$DOMAIN")

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