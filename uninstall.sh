run_uninstall() {
    local INSTALL_DIR="/opt/nexa"
    local CONFIG_DIR="$HOME/.config/nexa"
    local BIN_LINK="/usr/local/bin/nexa"

    echo -e "\n${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                NOVA NEXA - UNINSTALL                         ${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"

    echo -e "\n  ${RED}⚠ This will remove Nova Nexa from your system.${NC}"
    echo -e "  The following will be deleted:"
    echo -e "    - $INSTALL_DIR          (tool files)"
    echo -e "    - $BIN_LINK (CLI symlink)"
    echo -e "    - $CONFIG_DIR     (your settings)"
    echo -e "\n  ${YELLOW}Note: Your projects in ~/projects/ will NOT be affected.${NC}"

    echo -e ""
    read -p "  Are you sure? Type 'yes' to confirm: " confirm

    if [ "$confirm" != "yes" ]; then
        echo -e "\n  ${GREEN}Uninstall cancelled.${NC}"
        return 0
    fi

    echo -e "\n  ${BLUE}Removing Nova Nexa...${NC}"

    # 1. Remove binary symlink
    if [ -L "$BIN_LINK" ]; then
        echo -n "  Removing CLI symlink...   "
        sudo rm "$BIN_LINK"
        echo -e "${GREEN}✓${NC}"
    fi

    # 2. Remove tool directory
    if [ -d "$INSTALL_DIR" ]; then
        echo -n "  Removing tool files...    "
        sudo rm -rf "$INSTALL_DIR"
        echo -e "${GREEN}✓${NC}"
    fi

    # 3. Remove user config directory
    if [ -d "$CONFIG_DIR" ]; then
        echo -n "  Removing user config...   "
        rm -rf "$CONFIG_DIR"
        echo -e "${GREEN}✓${NC}"
    fi

    echo -e "\n  ${GREEN}✓ Nova Nexa has been uninstalled.${NC}"
    echo -e "  Goodbye! To reinstall, run the curl command from GitHub."
    echo -e "  (Closing session...)\n"
    
    # Exit the main loop in main.sh by exiting with a special code or just exiting
    exit 0
}
