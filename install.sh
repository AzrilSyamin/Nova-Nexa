#!/bin/bash

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
        unzip -q "$TEMP_SETUP/nexa.zip" -d "$TEMP_SETUP"
        # Find the extracted directory (e.g., Nova-Nexa-main)
        EXTRACTED_DIR=$(find "$TEMP_SETUP" -mindepth 1 -maxdepth 1 -type d)
        cd "$EXTRACTED_DIR" || exit
    fi

    # Run all modular scripts in order
    for script in script/*.sh; do
        if [ -f "$script" ]; then
            echo -e "\n${YELLOW}Running $script...${NC}"
            chmod +x "$script"
            ./"$script"
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
    sudo cp -r ./* "$INSTALL_DIR"
else
    echo -e "${GREEN}Downloading Nova Nexa tool from GitHub...${NC}"
    TEMP_DIR=$(mktemp -d)
    
    # Download ZIP
    curl -sSL "$ZIP_URL" -o "$TEMP_DIR/nexa.zip"
    
    # Extract ZIP
    unzip -q "$TEMP_DIR/nexa.zip" -d "$TEMP_DIR"
    
    # Move files to permanent home
    # Use find to get the extracted directory name dynamically
    EXTRACTED_DIR=$(find "$TEMP_DIR" -mindepth 1 -maxdepth 1 -type d)
    sudo cp -ra "$EXTRACTED_DIR"/. "$INSTALL_DIR"
    
    # Cleanup
    rm -rf "$TEMP_DIR"
fi

# 5. Final Touch: Permissions and Symlink
echo -e "${GREEN}Setting permissions and creating symlink...${NC}"
sudo chmod +x "$INSTALL_DIR/main.sh"
sudo ln -sf "$INSTALL_DIR/main.sh" "$BIN_LINK"

echo -e "\n${BLUE}------------------------------------------${NC}"
echo -e "${GREEN}Installation complete!${NC}"
echo -e "You can now run ${YELLOW}'nexa'${NC} from anywhere."
echo -e "${BLUE}------------------------------------------${NC}"
