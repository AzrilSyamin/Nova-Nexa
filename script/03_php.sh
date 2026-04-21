#!/bin/bash

# Load utilities
source utils/utils.sh

nexa_header "3/10: Installing Multiple PHP Versions"

# Add Ondrej PHP PPA
echo -e "${GREEN}Adding Ondrej PHP PPA...${NC}"
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update

PHP_VERSIONS=("7.4" "8.1" "8.2" "8.3" "8.4")
EXTENSIONS="fpm cli common mysql pgsql sqlite3 curl gd mbstring xml zip bcmath intl readline opcache redis imagick"

for VERSION in "${PHP_VERSIONS[@]}"; do
    echo -e "${GREEN}Installing PHP $VERSION and extensions...${NC}"
    PKGS=""
    for EXT in $EXTENSIONS; do
        PKGS="$PKGS php$VERSION-$EXT"
    done
    # Add the base php package
    PKGS="php$VERSION $PKGS"
    
    sudo apt install -y $PKGS
done

echo -e "${GREEN}PHP versions installation complete!${NC}"
php -v
