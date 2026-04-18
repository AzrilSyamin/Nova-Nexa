#!/bin/bash

# --- Color Definitions ---
GREEN='\033[0;32m'
BLUE='\033[1;34m'
NC='\033[0m'

echo -e "${BLUE}------------------------------------------${NC}"
echo -e "${BLUE}  5/10: Installing MySQL                  ${NC}"
echo -e "${BLUE}------------------------------------------${NC}"

echo -e "${GREEN}Installing MySQL Server...${NC}"
sudo apt install -y mysql-server

echo -e "${GREEN}Configuring MySQL root user (empty password for dev)...${NC}"
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY ''; FLUSH PRIVILEGES;"

echo -e "${GREEN}Configuring MySQL auto-start in .bashrc...${NC}"
if ! grep -q "sudo service mysql start" ~/.bashrc; then
    echo "sudo service mysql start" >> ~/.bashrc
    echo -e "${GREEN}Added to .bashrc${NC}"
else
    echo -e "${GREEN}Already in .bashrc${NC}"
fi

# Start service now
sudo service mysql start

echo -e "${GREEN}MySQL installation and configuration complete!${NC}"
