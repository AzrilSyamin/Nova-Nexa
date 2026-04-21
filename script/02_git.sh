#!/bin/bash

# Load utilities
source utils/utils.sh

nexa_header "2/10: Installing Git"

if command -v git &> /dev/null; then
    echo -e "${GREEN}Git is already installed: $(git --version)${NC}"
else
    echo -e "${GREEN}Installing Git...${NC}"
    sudo apt install -y git
    echo -e "${GREEN}Git installation complete!${NC}"
fi
