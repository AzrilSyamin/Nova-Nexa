#!/bin/bash

# Load utilities
source utils/utils.sh

nexa_header "5/10: Installing MySQL"

echo -e "${GREEN}Installing MySQL Server...${NC}"
sudo apt install -y mysql-server

# Start service immediately (necessary for Docker since policy-rc.d prevents auto-start)
sudo service mysql start

echo -e "${GREEN}Configuring MySQL: Creating dedicated user '$(whoami)' for remote & local access...${NC}"
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';"
sudo mysql -e "CREATE USER IF NOT EXISTS '$(whoami)'@'%' IDENTIFIED WITH mysql_native_password BY '';"
sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO '$(whoami)'@'%' WITH GRANT OPTION;"
sudo mysql -e "FLUSH PRIVILEGES;"

echo -e "${GREEN}Configuring default MySQL client to use TCP (Bypassing Socket issues)...${NC}"
sudo bash -c 'cat > /etc/mysql/conf.d/nexa-client.cnf' << EOF
[client]
protocol=tcp
host=127.0.0.1
EOF

# Restart MySQL to apply any changes if needed (optional for client config, but good for stability)
sudo service mysql restart

echo -e "${GREEN}MySQL installation and configuration complete!${NC}"
