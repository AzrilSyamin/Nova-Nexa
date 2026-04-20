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

    # ── Show help ─────────────────────────────────────────────────
    if [ -z "$1" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        nexa_header "NOVA NEXA - NEW SITE"
        echo -e "\nUsage: ${GREEN}new${NC} <name> --cat=<category> [options]\n"

        echo -e "${YELLOW}Categories (required):${NC}"
        printf "  ${GREEN}%-15s${NC} %-40s\n" "--cat=dev" "~/projects/dev/<name>     → <name>.dev.test"
        printf "  ${YELLOW}%-15s${NC} %-40s\n" "--cat=staging" "~/projects/staging/<name> → <name>.staging.test"
        printf "  ${BLUE}%-15s${NC} %-40s\n" "--cat=study" "~/projects/study/<name>   → <name>.study.test"

        echo -e "\n${YELLOW}PHP Options:${NC}"
        printf "  %-15s %-40s\n" "(no flag)" "Plain PHP project"
        printf "  ${CYAN}%-15s${NC} %-40s\n" "--laravel" "Install latest Laravel"
        printf "  ${CYAN}%-15s${NC} %-40s\n" "--laravel=11" "Install specific Laravel version"
        printf "  ${CYAN}%-15s${NC} %-40s\n" "--php=8.3" "Specify PHP version (default: 8.2)"

        echo -e "\n${YELLOW}JavaScript Options (Reverse Proxy):${NC}"
        printf "  ${CYAN}%-15s${NC} %-40s\n" "--react" "React + Vite   (port 5173)"
        printf "  ${CYAN}%-15s${NC} %-40s\n" "--next" "Next.js        (port 3000)"
        printf "  ${CYAN}%-15s${NC} %-40s\n" "--vue" "Vue + Vite     (port 5173)"
        printf "  ${CYAN}%-15s${NC} %-40s\n" "--nuxt" "Nuxt.js        (port 3000)"
        printf "  ${CYAN}%-15s${NC} %-40s\n" "--express" "Express.js     (port 3000)"
        printf "  ${WHITE}%-15s${NC} %-40s\n" "--port=XXXX" "Override development port manually"

        echo -e "\n${CYAN}Examples:${NC}"
        echo -e "  nexa > ${GREEN}new myapp --cat=dev --laravel=11 --php=8.3${NC}"
        echo -e "  nexa > ${GREEN}new myapp --cat=study --react${NC}"
        echo -e "  nexa > ${GREEN}new myapp --cat=staging --next --port=3001${NC}"
        echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}\n"
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
#  CREATE NGINX CONFIG & RELOAD SERVICES
# ══════════════════════════════════════════

    if [ -n "$JS_FRAMEWORK" ]; then
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