#!/bin/bash

# Color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored text
print_colored() {
    echo -e "${2}${1}${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Display banner
echo -e "${CYAN}

                                            
  /██   /██  /██████      /██████   /███████
 |  ██ /██/ /██__  ██    /██__  ██ /██_____/
  \  ████/ | ██  \ ██   | ██  \__/|  ██████ 
   >██  ██ | ██  | ██   | ██       \____  ██
  /██/\  ██|  ██████//██| ██       /███████/
 |__/  \__/ \______/|__/|__/      |_______/ 
 ---------------------------------------------
 github.com/incredimo | aghil@xo.rs | xo.rs
 ---------------------------------------------
 CHECKING AND INSTALLING GIT ON LINUX
 ---------------------------------------------
${NC}"

# Check if the script is being run with root privileges
if [[ $EUID -ne 0 ]]; then
    print_colored "This script must be run as root. Please use 'sudo' or log in as the root user." $RED
    exit 1
fi

# Update package lists
print_colored "Updating package lists..." $CYAN
apt-get update || { print_colored "Failed to update package lists. Please check your internet connection." $RED; exit 1; }

# Install required packages
print_colored "Installing required packages..." $CYAN
apt-get install -y software-properties-common || { print_colored "Failed to install required packages." $RED; exit 1; }

# Check if Git is already installed
if command_exists git; then
    print_colored "Git is already installed. Checking version..." $YELLOW
    git --version
else
    # Install Git
    print_colored "Installing Git..." $CYAN
    apt-get install -y git || { print_colored "Failed to install Git." $RED; exit 1; }
fi

# Verify Git installation
if command_exists git; then
    print_colored "Git has been successfully installed/updated." $GREEN
    git --version
else
    print_colored "Git installation verification failed. Please check the installation logs." $RED
    exit 1
fi

# Optional: Configure Git user details
read -p "Do you want to configure Git user details now? (y/n): " configure_git

if [[ $configure_git == "y" || $configure_git == "Y" ]]; then
    read -p "Enter your name: " git_name
    read -p "Enter your email: " git_email

    git config --global user.name "$git_name" || { print_colored "Failed to configure Git user name." $RED; exit 1; }
    git config --global user.email "$git_email" || { print_colored "Failed to configure Git user email." $RED; exit 1; }

    print_colored "Git user details configured successfully." $GREEN
else
    print_colored "Skipping Git user configuration." $YELLOW
fi

print_colored "Git installation and setup complete." $GREEN
