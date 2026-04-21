#!/bin/bash

# Load utilities
source utils/utils.sh

nexa_header "4/10: Installing Composer"

if command -v composer &> /dev/null; then
    echo -e "${GREEN}Composer is already installed: $(composer --version | head -n 1)${NC}"
else
    echo -e "${GREEN}Downloading and installing Composer...${NC}"
    cd ~
    curl -sS https://getcomposer.org/installer -o composer-setup.php
    sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    rm composer-setup.php
    echo -e "${GREEN}Composer installation complete!${NC}"
fi
