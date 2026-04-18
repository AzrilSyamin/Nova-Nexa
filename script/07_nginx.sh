#!/bin/bash

# --- Color Definitions ---
GREEN='\033[0;32m'
BLUE='\033[1;34m'
NC='\033[0m'

echo -e "${BLUE}------------------------------------------${NC}"
echo -e "${BLUE}  7/10: Installing Nginx                  ${NC}"
echo -e "${BLUE}------------------------------------------${NC}"

echo -e "${GREEN}Installing Nginx...${NC}"
sudo apt install -y nginx

echo -e "${GREEN}Configuring Nginx auto-start in .bashrc...${NC}"
if ! grep -q "sudo service nginx start" ~/.bashrc; then
    echo "sudo service nginx start" >> ~/.bashrc
    echo -e "${GREEN}Added to .bashrc${NC}"
else
    echo -e "${GREEN}Already in .bashrc${NC}"
fi

# Remove default site if exists
if [ -f /etc/nginx/sites-enabled/default ]; then
    echo -e "${GREEN}Removing default Nginx site configuration...${NC}"
    sudo rm /etc/nginx/sites-enabled/default
fi

# Start service now
sudo service nginx start

echo -e "${GREEN}Nginx installation and configuration complete!${NC}"
