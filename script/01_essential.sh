#!/bin/bash

# Load utilities
source utils/utils.sh

nexa_header "1/10: Installing Essential Build Tools"

# Update package lists
echo -e "${GREEN}Updating package lists...${NC}"
sudo apt update

# Upgrade packages
echo -e "${GREEN}Upgrading packages...${NC}"
sudo apt upgrade -y

# Install essential tools
echo -e "${GREEN}Installing essential build tools...${NC}"
sudo apt install -y build-essential curl wget unzip zip software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# Create project directories
echo -e "${GREEN}Creating project directories in ~/projects/...${NC}"
mkdir -p ~/projects/dev ~/projects/staging ~/projects/study

echo -e "${GREEN}Essential tools installation complete!${NC}"
