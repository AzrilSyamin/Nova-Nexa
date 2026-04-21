#!/bin/bash

# Load utilities
source utils/utils.sh

nexa_header "9/10: Installing Redis (Optional)"

echo -e "${GREEN}Installing Redis Server...${NC}"
sudo apt install -y redis-server


# Start service now
sudo service redis-server start

echo -e "${GREEN}Redis installation and configuration complete!${NC}"
redis-cli ping
