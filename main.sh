#!/bin/bash

# --- Sudo Fallback for Minimal Environments ---
if ! command -v sudo >/dev/null 2>&1; then
    if [ "$(id -u)" -eq 0 ]; then
        sudo() {
            "$@"
        }
        export -f sudo
    else
        echo -e "\033[0;31mError: 'sudo' is not installed and you are not running as root.\033[0m"
        echo "Please run this script as root or install 'sudo' first."
        exit 1
    fi
fi

# Define the base directory where other scripts live
BASE_DIR="/opt/nexa"
NEXA_VERSION="v0.1.1"

# Import (Source) the functions from other files
source "$BASE_DIR/commands/list.sh"
source "$BASE_DIR/commands/new.sh"
source "$BASE_DIR/commands/attach.sh"
source "$BASE_DIR/commands/del.sh"
source "$BASE_DIR/utils/utils.sh"
source "$BASE_DIR/commands/config.sh"
source "$BASE_DIR/commands/update.sh"
source "$BASE_DIR/commands/uninstall.sh"

# Load user configuration
NEXA_CONFIG="$HOME/.config/nexa/config.sh"
if [ -f "$NEXA_CONFIG" ]; then
    source "$NEXA_CONFIG"
else
    # Fallback to default if config not found
    NEXA_HOSTS_SYNC_DIR="/mnt/c/wsl-hosts-sync"
fi


# --- Color Definitions ---
BLUE='\033[1;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m' # Deprecated, keep for compatibility if needed
WHITE='\033[1;37m'
NC='\033[0m'

# Function to show help menu
nexa_help() {
    echo -e "\n${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}             NOVA NEXA - WSL2 Development Tool             ${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "\nUsage: ${GREEN}<command>${NC} [options]"
    echo -e "Example: ${GREEN}new${NC} myapp --cat=dev --laravel\n"
    
    echo -e "${YELLOW}Available Commands:${NC}"
    printf "  ${GREEN}%-10s${NC} %-40s\n" "new" "Create a new site (PHP/Laravel/JS/React/Next/etc)"
    printf "  ${YELLOW}%-10s${NC} %-40s\n" "attach" "Attach existing project folder to Nginx + SSL"
    printf "  ${RED}%-10s${NC} %-40s\n" "del" "Remove site configuration and SSL"
    printf "  ${CYAN}%-10s${NC} %-40s\n" "help" "Show this help menu"
    printf "  ${WHITE}%-10s${NC} %-40s\n" "config" "Manage Nova Nexa settings"
    printf "  ${CYAN}%-10s${NC} %-40s\n" "update" "Check and apply Nova Nexa updates"
    printf "  ${RED}%-10s${NC} %-40s\n" "uninstall" "Completely remove Nova Nexa from system"
    printf "  ${WHITE}%-10s${NC} %-40s\n" "exit" "Exit Nova Nexa"

    echo -e "\n${YELLOW}Project Categories:${NC}"
    echo -e "  Nova Nexa organizes projects into three categories:"
    echo -e "  - ${GREEN}dev${NC}     : Active development / real projects"
    echo -e "  - ${YELLOW}staging${NC} : Testing / pre-production"
    echo -e "  - ${BLUE}study${NC}   : Learning, experiments & scratchpads"

    echo -e "\n${CYAN}Tips:${NC}"
    echo -e "  - Run ${GREEN}<command> --help${NC} for detailed options of any command."
    echo -e "  - Example: ${GREEN}new --help${NC} or ${YELLOW}attach --help${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}\n"
}

wait_user() {
    echo -e "\n${BLUE}-------------------------------------------${NC}"
    read -p "Press [Enter] to continue..."
}

# Main Loop
while true; do
    show_list  # Function from list.sh
    
    read -e -p "nexa > " input

    # If input is not empty, save it to session history
    [[ -n "$input" ]] && history -s -- "$input"

    set -- $input
    COMMAND=$1
    shift

    case $COMMAND in
        new)
            run_newsite "$@"
            wait_user ;;
        attach)
            run_attachsite "$@"
            wait_user ;;
        del)
            run_delsite "$@"
            wait_user ;;
        config)
            run_config
            wait_user ;;
        update)
            run_update
            wait_user ;;
        uninstall)
            run_uninstall ;;
        help | -h | --help)
            nexa_help
            # Add a small pause so user can read before screen clears
            read -p "Press Enter to continue..."
            ;;
        exit | quit | q)
            echo "Goodbye!"
            break
            ;;
        "")
            # Handle empty Enter key (do nothing)
            ;;
        *)
            # This handles any undefined commands
            echo -e "${RED}Unknown command: '$COMMAND'${NC}"
            nexa_help
            read -p "Press Enter to continue..."
            ;;
    esac
done