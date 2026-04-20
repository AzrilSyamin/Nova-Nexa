run_config() {
    local CONFIG_FILE="$HOME/.config/nexa/config.sh"

    # Load current value
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
    
    local current_dir="${NEXA_HOSTS_SYNC_DIR:-/mnt/c/wsl-hosts-sync}"
    local current_drive=$(echo "$current_dir" | cut -d'/' -f3)

    echo -e "\n${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                  NOVA NEXA - SETTINGS                        ${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "\n${YELLOW}Current Settings:${NC}"
    printf "  ${CYAN}%-25s${NC} %s\n" "Hosts Sync Directory:" "$current_dir"
    echo ""

    echo -e "${YELLOW}What would you like to change?${NC}"
    printf "  ${GREEN}%-5s${NC} %-40s\n" "1)" "Change Hosts Sync drive letter"
    printf "  ${WHITE}%-5s${NC} %-40s\n" "q)" "Cancel / Go back"
    echo ""
    read -p "Choose option: " choice

    case $choice in
        1)
            echo ""
            echo -e "  Current drive: ${YELLOW}${current_drive}:${NC}"
            read -p "  Enter new Windows drive letter (e.g. D, E): " new_drive
            if [ -z "$new_drive" ]; then
                echo "  Cancelled. No changes made."
                return 0
            fi

            new_drive_lower=$(echo "$new_drive" | tr '[:upper:]' '[:lower:]')
            new_dir="/mnt/${new_drive_lower}/wsl-hosts-sync"

            # Validate: check if the new path exists
            if [ ! -d "$new_dir" ]; then
                echo -e "  ${RED}⚠ Warning: '$new_dir' does not exist.${NC}"
                echo -e "  Make sure you have created 'wsl-hosts-sync' folder on ${new_drive}: in Windows."
                read -p "  Save anyway? (y/N): " force_save
                [[ ! "$force_save" =~ ^[Yy]$ ]] && { echo "  Cancelled."; return 0; }
            fi

            # Update the config file
            if [ -f "$CONFIG_FILE" ]; then
                sed -i "s|NEXA_HOSTS_SYNC_DIR=.*|NEXA_HOSTS_SYNC_DIR=\"$new_dir\"|" "$CONFIG_FILE"
            else
                mkdir -p "$(dirname "$CONFIG_FILE")"
                echo "NEXA_HOSTS_SYNC_DIR=\"$new_dir\"" > "$CONFIG_FILE"
            fi

            # Reload the config in current session
            source "$CONFIG_FILE"
            NEXA_HOSTS_SYNC_DIR="$new_dir"

            echo -e "  ${GREEN}✓ Config updated! Hosts Sync directory is now: $new_dir${NC}"
            echo -e "  ${YELLOW}Changes take effect immediately.${NC}"
            ;;
        q|Q|"")
            echo "  Cancelled."
            ;;
        *)
            echo "  Invalid option."
            ;;
    esac
}
