#!/bin/bash

# Define the base directory where other scripts live
BASE_DIR="/opt/nexa"

# Import (Source) the functions from other files
source "$BASE_DIR/list.sh"
source "$BASE_DIR/new.sh"
source "$BASE_DIR/attach.sh"
source "$BASE_DIR/del.sh"

# --- Color Definitions ---
BLUE='\033[1;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Function to show help menu
nexa_help() {
    echo -e "\nUsage: <action> or <action> --help for specific info"
    echo -e "Example: new --help\n"
    echo -e "Available Actions:"
    
    printf "  ${GREEN}%-10s${NC} %-40s\n" "new" "- Create a new site project"
    printf "  ${YELLOW}%-10s${NC} %-40s\n" "attach" "- Attach an existing site to Nginx"
    printf "  ${RED}%-10s${NC} %-40s\n" "del" "- Delete a site configuration"
    printf "  ${BLUE}%-10s${NC} %-40s\n" "list" "- Refresh and show the site list"
    printf "  ${CYAN}%-10s${NC} %-40s\n" "help / -h" "- Show this help menu"
    
    echo -e "  %-10s %-40s\n" "exit" "Close the nexa program"
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
        list)
            # Just continue loop to trigger show_list again
            ;;
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