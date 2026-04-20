run_update() {
    local INSTALL_DIR="/opt/nexa"
    local ZIP_URL="https://github.com/azrilsyamin/nova-nexa/archive/refs/heads/main.zip"
    local TAGS_API="https://api.github.com/repos/azrilsyamin/nova-nexa/tags"

    nexa_header "NOVA NEXA - UPDATE"
    echo -e "\n  Current version : ${YELLOW}${NEXA_VERSION:-unknown}${NC}"

    # 1. Check internet first
    echo -e "  Checking internet connection..."
    check_internet || return 1

    # 2. Fetch latest tag from GitHub Tags API
    echo -e "  Checking for updates..."
    local latest_version
    latest_version=$(curl -sSL "$TAGS_API" \
        | grep '"name"' | head -1 \
        | sed 's/.*"name": *"\([^"]*\)".*/\1/')

    if [ -z "$latest_version" ]; then
        echo -e "  ${RED}✗ Could not fetch version info from GitHub.${NC}"
        return 1
    fi

    echo -e "  Latest version  : ${GREEN}$latest_version${NC}"

    # 3. Compare versions
    if [ "${NEXA_VERSION:-unknown}" = "$latest_version" ]; then
        echo -e "\n  ${GREEN}✓ You are already on the latest version!${NC}"
        return 0
    fi

    # 4. Ask confirmation
    echo -e "\n  ${YELLOW}A new update is available!${NC}"
    read -p "  Update now? (y/N): " confirm
    [[ ! "$confirm" =~ ^[Yy]$ ]] && { echo "  Update cancelled."; return 0; }

    # 5. Download, clean replace, fix permissions
    echo -e "\n  ${BLUE}Downloading update...${NC}"
    local TEMP_DIR
    TEMP_DIR=$(mktemp -d)

    if ! curl -sSL "$ZIP_URL" -o "$TEMP_DIR/nexa.zip"; then
        echo -e "  ${RED}✗ Download failed. Please try again later.${NC}"
        rm -rf "$TEMP_DIR"
        return 1
    fi

    echo -e "  ${BLUE}Replacing old files...${NC}"
    unzip -q "$TEMP_DIR/nexa.zip" -d "$TEMP_DIR"
    local EXTRACTED_DIR
    EXTRACTED_DIR=$(find "$TEMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -1)

    sudo rm -rf "$INSTALL_DIR"
    sudo mkdir -p "$INSTALL_DIR"
    sudo cp -ra "$EXTRACTED_DIR"/. "$INSTALL_DIR"
    sudo chmod +x "$INSTALL_DIR/main.sh"
    sudo ln -sf "$INSTALL_DIR/main.sh" /usr/local/bin/nexa
    rm -rf "$TEMP_DIR"

    echo -e "\n  ${GREEN}✓ Nova Nexa updated to $latest_version!${NC}"
    echo -e "  ${YELLOW}Please restart Nova Nexa for changes to take effect.${NC}"
    echo -e "  (Type 'exit' then run 'nexa' again)\n"
}
