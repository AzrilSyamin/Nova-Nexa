#!/bin/bash

# --- Color Definitions ---
GREEN='\033[0;32m'
BLUE='\033[1;34m'
NC='\033[0m'

echo -e "${BLUE}------------------------------------------${NC}"
echo -e "${BLUE}  9/10: Installing Redis (Optional)       ${NC}"
echo -e "${BLUE}------------------------------------------${NC}"

echo -e "${GREEN}Installing Redis Server...${NC}"
sudo apt install -y redis-server

echo -e "${GREEN}Configuring Redis auto-start in .bashrc...${NC}"
if ! grep -q "sudo service redis-server start" ~/.bashrc; then
    echo "sudo service redis-server start" >> ~/.bashrc
    echo -e "${GREEN}Added to .bashrc${NC}"
else
    echo -e "${GREEN}Already in .bashrc${NC}"
fi

# Start service now
sudo service redis-server start

echo -e "${GREEN}Redis installation and configuration complete!${NC}"
redis-cli ping
