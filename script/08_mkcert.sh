#!/bin/bash

# Load utilities
source utils/utils.sh

nexa_header "8/10: Installing mkcert (SSL)"

echo -e "${GREEN}Installing libnss3-tools...${NC}"
sudo apt install -y libnss3-tools

if command -v mkcert &> /dev/null; then
    echo -e "${GREEN}mkcert is already installed.${NC}"
else
    echo -e "${GREEN}Downloading mkcert...${NC}"
    # Find latest version tag
    # Using a simple download for amd64 as specified in the guide
    curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
    chmod +x mkcert-v*-linux-amd64
    sudo mv mkcert-v*-linux-amd64 /usr/local/bin/mkcert
fi

echo -e "${GREEN}Setting up mkcert local CA...${NC}"
mkdir -p ~/.local/share/mkcert
mkcert -install

echo -e "${GREEN}mkcert installation complete!${NC}"
echo -e "${BLUE}Note: Remember to copy the rootCA.pem to Windows and install it in the Trust Root Authorities.${NC}"
echo -e "${BLUE}Command: cp \"\$(mkcert -CAROOT)/rootCA.pem\" /mnt/c/Users/yourusername/${NC}"
