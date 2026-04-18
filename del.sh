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
    local PENDING_FILE="/mnt/c/wsl-hosts-sync/pending.txt"

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

    # ── Queue hosts file removal ──────────────────────────────────
    remove_hosts_entry() {
        local domain=$1
        if [ -f "$PENDING_FILE" ]; then
            echo "REMOVE $domain" >> "$PENDING_FILE"
        else
            echo "REMOVE $domain" > "$PENDING_FILE"
        fi
    }

    # ── Core delete function ──────────────────────────────────────
    delete_site() {
        local DOMAIN=$1
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
        if [ -n "$PROJECT_DIR" ] && [ -d "$PROJECT_DIR" ]; then
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
        if [ -d "/mnt/c/wsl-hosts-sync" ]; then
            remove_hosts_entry "$DOMAIN"
            echo "  ✓ Hosts file will be updated in ~5 seconds"
        else
            echo "  ⚠ Windows bridge not found"
            echo "    Remove manually: $DOMAIN from C:\\Windows\\System32\\drivers\\etc\\hosts"
        fi

        # 7. Reload Nginx
        if sudo nginx -t 2>/dev/null; then
            sudo service nginx reload
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

    else
        # Name + --cat flag
        local PROJECT_NAME="$1"
        local CATEGORY=""
        for arg in "$@"; do
            case $arg in --cat=*) CATEGORY="${arg#*=}" ;; esac
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
    echo "  The following will be DELETED:"
    echo "════════════════════════════════════════"
    [ -d "$PROJ_FOLDER" ] \
        && echo "  📁 Folder : $PROJ_FOLDER" \
        || echo "  📁 Folder : (not found — will be skipped)"
    [ -f "$CONF" ]                          && echo "  ⚙  Nginx  : ${DOMAIN}.conf"
    [ -f "$CERTS_DIR/${DOMAIN}.pem" ]       && echo "  🔒 SSL    : ${DOMAIN}.pem"
    echo "  🌐 Hosts  : 127.0.0.1 $DOMAIN"
    echo "════════════════════════════════════════"
    echo ""

    read -p "Continue? (y/N): " confirm
    [[ ! "$confirm" =~ ^[Yy]$ ]] && { echo "Cancelled."; return 0; }

    delete_site "$DOMAIN"
}