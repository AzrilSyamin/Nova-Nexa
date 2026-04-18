#!/bin/bash

# --- Color Definitions ---
GREEN='\033[0;32m'
BLUE='\033[1;34m'
NC='\033[0m'

echo -e "${BLUE}------------------------------------------${NC}"
echo -e "${BLUE}  6/10: Installing NVM & Node.js          ${NC}"
echo -e "${BLUE}------------------------------------------${NC}"

if [ -d "$HOME/.nvm" ]; then
    echo -e "${GREEN}NVM is already installed.${NC}"
else
    echo -e "${GREEN}Installing NVM (Node Version Manager)...${NC}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi

# Load NVM for the current session
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo -e "${GREEN}Installing Node.js LTS...${NC}"
nvm install --lts
nvm use --lts

echo -e "${GREEN}Node.js installation complete!${NC}"
node -v
npm -v
