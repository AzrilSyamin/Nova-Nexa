show_list() {

    # Function to list sites (The code we built earlier)
    list_sites() {
        clear
        echo -e "${BLUE}============================================================================${NC}"
        printf "${BLUE}%-20s %-30s %-10s %-10s${NC}\n" "PROJECT" "DOMAIN" "PORT/VER" "TYPE"
        echo -e "${BLUE}============================================================================${NC}"

        for file in /etc/nginx/sites-available/*.conf; do
            [ -e "$file" ] || continue
            local PROJECT=$(basename "$file" .conf | sed 's/.test//' | sed 's/.staging//' | sed 's/.dev//' | sed 's/.study//')
            local DOMAIN=$(grep "server_name" "$file" | head -n 1 | awk '{print $2}' | tr -d ';')
            
            if grep -q "proxy_pass" "$file"; then
                local TYPE="JS"; COLOR=$GREEN
                local PORT=$(grep "proxy_pass" "$file" | head -n 1 | grep -oP '127\.0\.0\.1:\K[0-9]+')
            elif grep -q "fastcgi_pass" "$file"; then
                local TYPE="PHP"; COLOR=$YELLOW
                local PORT=$(grep -oE "php[0-9.]+" "$file" | head -n 1 | sed 's/php//')
            else
                local TYPE="Static"; PORT="-"; COLOR=$NC
            fi
            printf "%-20s %-30s ${COLOR}%-10s${NC} %-10s\n" "$PROJECT" "$DOMAIN" "$PORT" "$TYPE"
        done
        echo -e "${BLUE}============================================================================${NC}"
        echo -e "Available commands: ${GREEN}new${NC} | ${YELLOW}attach${NC} | ${RED}del${NC} | ${WHITE}config${NC} | ${CYAN}update${NC} | ${RED}uninstall${NC} | help | exit"
    }
    list_sites
}
