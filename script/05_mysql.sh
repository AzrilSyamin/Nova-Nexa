#!/bin/bash

# Load utilities
source utils/utils.sh

nexa_header "5/10: Installing MySQL"

echo -e "${GREEN}Installing MySQL Server...${NC}"
sudo apt install -y mysql-server

# Start service immediately (necessary for Docker since policy-rc.d prevents auto-start)
sudo service mysql start

echo -e "${GREEN}Configuring MySQL: Creating dedicated user '$(whoami)'...${NC}"
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';"
sudo mysql -e "CREATE USER IF NOT EXISTS '$(whoami)'@'localhost' IDENTIFIED WITH mysql_native_password BY '';"
sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO '$(whoami)'@'localhost' WITH GRANT OPTION;"
sudo mysql -e "FLUSH PRIVILEGES;"

# Fix Socket Permission Denied (Error 13) by adding user to mysql group
sudo usermod -aG mysql $(whoami)

echo -e "${GREEN}MySQL installation and configuration complete!${NC}"
