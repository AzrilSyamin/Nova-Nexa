#!/bin/bash

# --- Color Definitions ---
GREEN='\033[0;32m'
BLUE='\033[1;34m'
NC='\033[0m'

echo -e "${BLUE}------------------------------------------${NC}"
echo -e "${BLUE}  2/10: Installing Git                    ${NC}"
echo -e "${BLUE}------------------------------------------${NC}"

if command -v git &> /dev/null; then
    echo -e "${GREEN}Git is already installed: $(git --version)${NC}"
else
    echo -e "${GREEN}Installing Git...${NC}"
    sudo apt install -y git
    echo -e "${GREEN}Git installation complete!${NC}"
fi
