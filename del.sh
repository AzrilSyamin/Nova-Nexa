run_delsite() {
    # ══════════════════════════════════════════════════════════════
    #  del — Remove a project: folder, SSL cert, Nginx, hosts
    #
    #  Usage:
    #    del <name>.<category>.test   (full domain)
    #    del <name> --cat=<category>  (name + category)
    #    del                          (interactive — shows list)
    # ══════════════════════════════════════════════════════════════

    local CERTS_DIR="$HOME/.local/share/mkcert"

    # ── Show help ─────────────────────────────────────────────────
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        echo -e "\n${BLUE}══════════════════════════════════════════════════════════════${NC}"
        echo -e "${BLUE}                 NOVA NEXA - DELETE SITE                      ${NC}"
        echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
        echo -e "\nUsage: ${RED}del${NC} <name> --cat=<category> [options]"
        echo -e "       ${RED}del${NC} <domain>\n"

        echo -e "${YELLOW}Methods:${NC}"
        printf "  ${GREEN}%-30s${NC} %-40s\n" "del <domain>" "Delete using full domain (e.g. myapp.dev.test)"
        printf "  ${YELLOW}%-30s${NC} %-40s\n" "del <name> --cat=<cat>" "Delete using project name and category"
        printf "  ${CYAN}%-30s${NC} %-40s\n" "del" "Interactive mode (shows a list to choose from)"

        echo -e "\n${YELLOW}Options:${NC}"
        printf "  ${WHITE}%-30s${NC} %-40s\n" "--keep" "Keep project folder (delete configs only)"

        echo -e "\n${CYAN}What it does:${NC}"
        echo -e "  - Deletes the project folder"
        echo -e "  - Removes Nginx configuration"
        echo -e "  - Deletes SSL certificates"
        echo -e "  - Queues Windows hosts file removal"
        echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}\n"
        return 0
    fi

    # ── List all active sites ─────────────────────────────────────
    show_sites() {
        echo ""
        echo "Active sites:"
        echo "────────────────────────────────────────────────────────"
        printf "  %-38s %-10s %s\n" "Domain" "Category" "Status"
        echo "  ──────────────────────────────────────────────────────"

        local found=false
        for conf in /etc/nginx/sites-enabled/*.conf; do
            [ -f "$conf" ] || continue
            domain=$(basename "$conf" .conf)
            category=$(echo "$domain" | awk -F. '{print $(NF-1)}')

            # Try to get project folder from nginx root line
            root_line=$(grep -E "^\s+root " "$conf" 2>/dev/null | head -1 | awk '{print $2}' | tr -d ';')
            if [ -n "$root_line" ]; then
                folder=$(echo "$root_line" | sed 's|/public$||')
            else
                # JS project — derive from domain
                parts=(${domain//./ })
                folder="$HOME/projects/${parts[1]}/${parts[0]}"
            fi

            if [ -d "$folder" ]; then
                size=$(du -sh "$folder" 2>/dev/null | cut -f1)
                printf "  %-38s %-10s %s\n" "$domain" "[$category]" "✓ $size"
            else
                printf "  %-38s %-10s %s\n" "$domain" "[$category]" "⚠ folder missing"
            fi
            found=true
        done

        if [ "$found" = false ]; then
            echo "  (no active sites)"
        fi
        echo "────────────────────────────────────────────────────────"
        echo ""
    }

    # ── Core delete function ──────────────────────────────────────
    delete_site() {
        local DOMAIN=$1
        local KEEP_FOLDER=${2:-false}
        local CONF="/etc/nginx/sites-available/${DOMAIN}.conf"

        echo ""
        echo "════════════════════════════════════════"
        echo "  Deleting: $DOMAIN"
        echo "════════════════════════════════════════"

        # 1. Resolve project folder from nginx config
        PROJECT_DIR=""
        if [ -f "$CONF" ]; then
            root_line=$(grep -E "^\s+root " "$CONF" 2>/dev/null | head -1 | awk '{print $2}' | tr -d ';')
            if [ -n "$root_line" ]; then
                PROJECT_DIR=$(echo "$root_line" | sed 's|/public$||')
            else
                # JS project — derive from domain: name.cat.test
                parts=(${DOMAIN//./ })
                PROJECT_DIR="$HOME/projects/${parts[1]}/${parts[0]}"
            fi
        fi

        # 2. Delete project folder
        if [ "$KEEP_FOLDER" = true ]; then
            echo "  🔒 Project folder kept safe: $PROJECT_DIR"
        elif [ -n "$PROJECT_DIR" ] && [ -d "$PROJECT_DIR" ]; then
            rm -rf "$PROJECT_DIR"
            echo "  ✓ Project folder deleted: $PROJECT_DIR"
        else
            echo "  ⚠ Project folder not found (may have been deleted already)"
        fi

        # 3. Remove Nginx symlink
        if [ -L "/etc/nginx/sites-enabled/${DOMAIN}.conf" ]; then
            sudo rm "/etc/nginx/sites-enabled/${DOMAIN}.conf"
            echo "  ✓ Nginx sites-enabled removed"
        else
            echo "  ⚠ Nginx sites-enabled not found"
        fi

        # 4. Remove Nginx config
        if [ -f "$CONF" ]; then
            sudo rm "$CONF"
            echo "  ✓ Nginx sites-available removed"
        else
            echo "  ⚠ Nginx sites-available not found"
        fi

        # 5. Delete SSL certificates
        local cert_deleted=false
        for f in "$CERTS_DIR/${DOMAIN}.pem" "$CERTS_DIR/${DOMAIN}-key.pem"; do
            [ -f "$f" ] && rm "$f" && cert_deleted=true
        done
        [ "$cert_deleted" = true ] \
            && echo "  ✓ SSL certificates deleted" \
            || echo "  ⚠ SSL certificates not found"

        # 6. Queue Windows hosts removal
        update_windows_hosts "REMOVE" "$DOMAIN"

        # 7. Reload Nginx
        if sudo nginx -t 2>/dev/null; then
            reload_web_services "" >/dev/null
            echo "  ✓ Nginx reloaded"
        fi

        echo ""
        echo "════════════════════════════════════════"
        echo "  ✓ $DOMAIN deleted successfully!"
        echo "════════════════════════════════════════"
        echo ""
    }

    # ══════════════════════════════════════════
    #  RESOLVE DOMAIN FROM ARGUMENTS
    # ══════════════════════════════════════════

    local DOMAIN=""

    if [ -z "$1" ]; then
        # Interactive mode
        show_sites
        read -p "Enter domain to delete (or 'q' to cancel): " input
        [ "$input" = "q" ] || [ -z "$input" ] && { echo "Cancelled."; return 0; }
        local DOMAIN="$input"

    elif [[ "$1" == --* ]]; then
        echo -e "\n${RED}Error: Project name or domain cannot start with '--'${NC}"
        echo "Usage: del <name> --cat=<category> or del <domain>"
        return 1

    elif echo "$1" | grep -q "\.test$"; then
        # Full domain passed: e.g. myapp.dev.test
        local DOMAIN="$1"
        local KEEP=false
        for arg in "$@"; do
            case $arg in --keep) KEEP=true ;; esac
        done

    else
        # Name + --cat flag
        local PROJECT_NAME="$1"
        local CATEGORY=""
        local KEEP=false
        for arg in "$@"; do
            case $arg in 
                --cat=*) CATEGORY="${arg#*=}" ;;
                --keep)  KEEP=true ;;
            esac
        done

        if [ -z "$CATEGORY" ]; then
            echo ""
            echo "Error: Specify category with --cat or pass the full domain."
            echo ""
            echo "Examples:"
            echo "  del myapp --cat=dev"
            echo "  del myapp.dev.test"
            echo "  del                   (interactive)"
            return 1
        fi

        local DOMAIN="${PROJECT_NAME}.${CATEGORY}.test"
    fi

    # ── Verify the site exists ────────────────────────────────────
    if [ ! -f "/etc/nginx/sites-available/${DOMAIN}.conf" ]; then
        echo ""
        echo "Error: No Nginx config found for '$DOMAIN'."
        show_sites
        return 1
    fi

    # ── Show what will be deleted ─────────────────────────────────
    local CONF="/etc/nginx/sites-available/${DOMAIN}.conf"
    local root_line=$(grep -E "^\s+root " "$CONF" 2>/dev/null | head -1 | awk '{print $2}' | tr -d ';')
    if [ -n "$root_line" ]; then
        local PROJ_FOLDER=$(echo "$root_line" | sed 's|/public$||')
    else
        local parts=(${DOMAIN//./ })
        local PROJ_FOLDER="$HOME/projects/${parts[1]}/${parts[0]}"
    fi

    echo ""
    echo "════════════════════════════════════════"
    echo "  Deletion Summary for $DOMAIN:"
    echo "════════════════════════════════════════"
    [ -f "$CONF" ]                          && echo "  ⚙  Nginx  : ${DOMAIN}.conf"
    [ -f "$CERTS_DIR/${DOMAIN}.pem" ]       && echo "  🔒 SSL    : ${DOMAIN}.pem"
    echo "  🌐 Hosts  : 127.0.0.1 $DOMAIN"
    
    if [ -d "$PROJ_FOLDER" ]; then
        echo -e "  📁 Folder : $PROJ_FOLDER ${YELLOW}(Optional)${NC}"
    else
        echo "  📁 Folder : (not found)"
    fi
    echo "════════════════════════════════════════"
    echo ""

    read -p "Continue with deletion? (y/N): " confirm
    [[ ! "$confirm" =~ ^[Yy]$ ]] && { echo "Cancelled."; return 0; }

    # If --keep wasn't passed, ask specifically about the folder
    if [ "$KEEP" = false ]; then
        echo -e "\n${YELLOW}Caution:${NC} Do you want to delete the project folder at $PROJ_FOLDER too?"
        read -p "(y/N): " del_folder
        if [[ ! "$del_folder" =~ ^[Yy]$ ]]; then
            KEEP=true
        fi
    fi

    delete_site "$DOMAIN" "$KEEP"
}