#!/bin/bash

# Load utilities
source utils/utils.sh

nexa_header "7/10: Installing Nginx"

echo -e "${GREEN}Installing Nginx...${NC}"
sudo apt install -y nginx


# Remove default site if exists
if [ -f /etc/nginx/sites-enabled/default ]; then
    echo -e "${GREEN}Removing default Nginx site configuration...${NC}"
    sudo rm /etc/nginx/sites-enabled/default
fi

# Start service now
sudo service nginx start

echo -e "${GREEN}Nginx installation and configuration complete!${NC}"
