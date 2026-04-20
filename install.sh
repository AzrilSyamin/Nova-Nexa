#!/bin/bash

# --- Sudo Fallback for Minimal Environments ---
if ! command -v sudo >/dev/null 2>&1; then
    if [ "$(id -u)" -eq 0 ]; then
        sudo() {
            "$@"
        }
        export -f sudo
    else
        echo -e "\033[0;31mError: 'sudo' is not installed and you are not running as root.\033[0m"
        echo "Please run this script as root or install 'sudo' first."
        exit 1
    fi
fi

# --- Color Definitions ---
GREEN='\033[0;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
INSTALL_DIR="/opt/nexa"
BIN_LINK="/usr/local/bin/nexa"
ZIP_URL="https://github.com/azrilsyamin/nova-nexa/archive/refs/heads/main.zip"

echo -e "${BLUE}------------------------------------------${NC}"
echo -e "${BLUE}        Nova Nexa Installer               ${NC}"
echo -e "${BLUE}------------------------------------------${NC}"

# 1. Basic Dependency Check for Installer
echo -e "${GREEN}Checking for installer dependencies...${NC}"
for cmd in curl unzip; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}Error: '$cmd' is not installed. Installing it now...${NC}"
        sudo apt update && sudo apt install -y $cmd
    fi
done

# --- Initial Connectivity Check ---
echo -e "${GREEN}Checking internet connection...${NC}"
if ! curl -sSf --max-time 5 "https://github.com" -o /dev/null 2>/dev/null; then
    echo -e "${RED}✗ No internet connection. Please check your network and try again.${NC}"
    exit 1
fi

# 2. Ask for Full Environment Setup (Part A)
echo -e "\n${YELLOW}Do you want to perform a Full Environment Setup?${NC}"
echo -e "This will install PHP (7.4-8.4), MySQL, Nginx, Node.js, mkcert, etc."
# Use /dev/tty to allow interactive input when run via pipe (curl | bash)
read -p "Perform full setup? (y/n): " confirm_setup < /dev/tty

if [[ "$confirm_setup" =~ ^[Yy]$ ]]; then
    echo -e "\n${BLUE}Starting Full Environment Setup...${NC}"
    
    # Check if script folder exists locally or we need to download it
    if [ ! -d "script" ] && [ ! -f "main.sh" ]; then
        echo -e "${YELLOW}Downloading environment setup scripts...${NC}"
        TEMP_SETUP=$(mktemp -d)
        curl -sSL "$ZIP_URL" -o "$TEMP_SETUP/nexa.zip"
        unzip -q "$TEMP_SETUP/nexa.zip" -d "$TEMP_SETUP" < /dev/null
        # Find the extracted directory (e.g., Nova-Nexa-main)
        EXTRACTED_DIR=$(find "$TEMP_SETUP" -mindepth 1 -maxdepth 1 -type d)
        cd "$EXTRACTED_DIR" || exit
    fi

    # Run all modular scripts in order
    for script in script/*.sh; do
        if [ -f "$script" ]; then
            chmod +x "$script"
            ./"$script" < /dev/null
            if [ $? -ne 0 ]; then
                echo -e "${RED}Error occurred while running $script. Continuing...${NC}"
            fi
        fi
    done
    
    # If we were in temp dir, go back
    if [ -n "$TEMP_SETUP" ]; then
        cd - > /dev/null || exit
        rm -rf "$TEMP_SETUP"
    fi
    
    echo -e "\n${GREEN}Environment Setup Complete!${NC}"
else
    echo -e "\n${YELLOW}Skipping Full Environment Setup.${NC}"
fi

# 3. Create target directory
echo -e "\n${GREEN}Installing Nova Nexa tool...${NC}"
sudo mkdir -p "$INSTALL_DIR"

# 4. Check if we are running locally (already have files) or remotely
if [ -f "main.sh" ]; then
    echo -e "${GREEN}Local files detected. Copying to $INSTALL_DIR...${NC}"
    sudo rm -rf "$INSTALL_DIR"
    sudo mkdir -p "$INSTALL_DIR"
    sudo cp -ra ./* "$INSTALL_DIR"
else
    echo -e "${GREEN}Downloading Nova Nexa tool from GitHub...${NC}"
    TEMP_DIR=$(mktemp -d)
    
    # Download ZIP
    curl -sSL "$ZIP_URL" -o "$TEMP_DIR/nexa.zip"
    
    # Extract ZIP
    unzip -q "$TEMP_DIR/nexa.zip" -d "$TEMP_DIR"
    
    # Move files to permanent home
    # Use find to get the extracted directory name dynamically
    EXTRACTED_DIR=$(find "$TEMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -1)
    
    # Clean replace
    sudo rm -rf "$INSTALL_DIR"
    sudo mkdir -p "$INSTALL_DIR"
    sudo cp -ra "$EXTRACTED_DIR"/. "$INSTALL_DIR"
    
    # Cleanup
    rm -rf "$TEMP_DIR"
fi

# 5. Final Touch: Permissions and Symlink
echo -e "${GREEN}Setting permissions and creating symlink...${NC}"
sudo chmod +x "$INSTALL_DIR/main.sh"
sudo ln -sf "$INSTALL_DIR/main.sh" "$BIN_LINK"

# 6. Setup user config if not already exists
CONFIG_DIR="$HOME/.config/nexa"
CONFIG_FILE="$CONFIG_DIR/config.sh"

if [ ! -f "$CONFIG_FILE" ]; then
    mkdir -p "$CONFIG_DIR"

    echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  Windows Hosts Sync Setup${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  Nova Nexa needs a shared folder on Windows to auto-sync"
    echo -e "  local domains to your Windows hosts file."
    echo -e ""
    echo -e "  A folder named ${GREEN}wsl-hosts-sync${NC} will be created on the"
    echo -e "  Windows drive you specify below."
    echo ""
    read -p "  Enter Windows drive letter (default: C): " drive_letter < /dev/tty
    drive_letter="${drive_letter:-C}"
    # Normalize: convert to lowercase for WSL path
    drive_lower=$(echo "$drive_letter" | tr '[:upper:]' '[:lower:]')

    cat > "$CONFIG_FILE" << EOF
# Nova Nexa Configuration File
# Edit this file or run 'nexa config' to change settings.

# Path to the WSL Hosts Sync folder (Windows-side bridge)
NEXA_HOSTS_SYNC_DIR="/mnt/${drive_lower}/wsl-hosts-sync"
EOF

    echo -e "  ${GREEN}✓ Config saved to $CONFIG_FILE${NC}"
    echo -e "  ${YELLOW}Remember: Create 'wsl-hosts-sync' folder on ${drive_letter}: in Windows.${NC}"
fi

echo -e "\n${BLUE}------------------------------------------${NC}"
echo -e "${GREEN}Installation complete!${NC}"
echo -e "You can now run ${YELLOW}'nexa'${NC} from anywhere."
echo -e "${BLUE}------------------------------------------${NC}"
