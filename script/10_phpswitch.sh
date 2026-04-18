#!/bin/bash

# --- Color Definitions ---
GREEN='\033[0;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}------------------------------------------${NC}"
echo -e "${BLUE}  10/10: Installing phpswitch Utility     ${NC}"
echo -e "${BLUE}------------------------------------------${NC}"

PHP_SWITCH_PATH="/usr/local/bin/phpswitch"
DO_INSTALL=true

if [ -f "$PHP_SWITCH_PATH" ]; then
    echo -e "${YELLOW}phpswitch utility already exists at $PHP_SWITCH_PATH.${NC}"
    read -p "Do you want to overwrite it? (y/n): " overwrite_switch
    if [[ ! "$overwrite_switch" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Skipping phpswitch installation.${NC}"
        DO_INSTALL=false
    fi
fi

if [ "$DO_INSTALL" = true ]; then
    echo -e "${GREEN}Creating/Updating phpswitch script in $PHP_SWITCH_PATH...${NC}"

    sudo bash -c "cat > $PHP_SWITCH_PATH" << 'EOF'
#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: phpswitch <version>"
    echo "Available: 7.4, 8.1, 8.2, 8.3, 8.4"
    echo ""
    echo "Current version:"
    php --version | head -n 1
    exit 1
fi

VERSION=$1

if [[ ! "$VERSION" =~ ^(7\.4|8\.1|8\.2|8\.3|8\.4)$ ]]; then
    echo "Invalid version. Available: 7.4, 8.1, 8.2, 8.3, 8.4"
    exit 1
fi

echo "Switching to PHP $VERSION..."
sudo update-alternatives --set php /usr/bin/php$VERSION
sudo update-alternatives --set phar /usr/bin/phar$VERSION
sudo update-alternatives --set phar.phar /usr/bin/phar.phar$VERSION

echo ""
echo "Switched to:"
php --version | head -n 1
EOF

    sudo chmod +x $PHP_SWITCH_PATH
    echo -e "${GREEN}phpswitch utility installation complete!${NC}"
    echo -e "${GREEN}You can now use 'phpswitch <version>' to switch between PHP versions.${NC}"
fi
