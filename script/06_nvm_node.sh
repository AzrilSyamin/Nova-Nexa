#!/bin/bash

# Load utilities
source utils/utils.sh

nexa_header "6/10: Installing NVM & Node.js"

if [ -d "$HOME/.nvm" ]; then
    echo -e "${GREEN}NVM is already installed.${NC}"
else
    echo -e "${GREEN}Installing NVM (Node Version Manager)...${NC}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi

# Load NVM for the current session
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo -e "${GREEN}Installing Node.js LTS...${NC}"
nvm install --lts
nvm use --lts

echo -e "${GREEN}Node.js installation complete!${NC}"

# Ensure NVM is loaded in .bashrc for future sessions
if ! grep -q "export NVM_DIR" ~/.bashrc; then
    echo -e "${GREEN}Adding NVM load lines to .bashrc...${NC}"
    echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >> ~/.bashrc
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >> ~/.bashrc
fi

node -v
npm -v
