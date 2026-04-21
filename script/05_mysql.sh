#!/bin/bash

# Load utilities
source utils/utils.sh

nexa_header "5/10: Installing MySQL"

echo -e "${GREEN}Installing MySQL Server...${NC}"
sudo apt install -y mysql-server

# Start service immediately (necessary for Docker since policy-rc.d prevents auto-start)
sudo service mysql start

echo -e "${GREEN}Configuring MySQL: Creating dedicated user '${USER}'...${NC}"
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';"
sudo mysql -e "CREATE USER IF NOT EXISTS '${USER}'@'localhost' IDENTIFIED WITH mysql_native_password BY '';"
sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO '${USER}'@'localhost' WITH GRANT OPTION;"
sudo mysql -e "FLUSH PRIVILEGES;"

echo -e "${GREEN}MySQL installation and configuration complete!${NC}"
