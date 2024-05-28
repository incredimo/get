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

# Function to run a command with or without sudo, based on user privileges
run_command() {
    if [[ $EUID -ne 0 ]]; then
        sudo "$@"
    else
        "$@"
    fi
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
INSTALLING GITHUB CLI ON DEBIAN
---------------------------------------------
${NC}"

# Check if wget is installed, if not install it
print_colored "Checking if wget is installed..." $CYAN
if ! command_exists wget; then
    print_colored "wget not found. Installing wget..." $YELLOW
    run_command apt update && run_command apt-get install wget -y || {
        print_colored "Failed to install wget. Please check your internet connection." $RED
        exit 1
    }
else
    print_colored "wget is already installed." $GREEN
fi

# Create the keyrings directory
print_colored "Creating /etc/apt/keyrings directory..." $CYAN
run_command mkdir -p -m 755 /etc/apt/keyrings || {
    print_colored "Failed to create /etc/apt/keyrings directory." $RED
    exit 1
}

# Download GitHub CLI GPG key
print_colored "Downloading GitHub CLI GPG key..." $CYAN
wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | run_command tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null || {
    print_colored "Failed to download GitHub CLI GPG key." $RED
    exit 1
}

# Set permissions for the GPG key
print_colored "Setting permissions for the GPG key..." $CYAN
run_command chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg || {
    print_colored "Failed to set permissions for the GPG key." $RED
    exit 1
}

# Add GitHub CLI repository to the sources list
print_colored "Adding GitHub CLI repository to sources list..." $CYAN
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | run_command tee /etc/apt/sources.list.d/github-cli.list > /dev/null || {
    print_colored "Failed to add GitHub CLI repository." $RED
    exit 1
}

# Update package lists
print_colored "Updating package lists..." $CYAN
run_command apt update || {
    print_colored "Failed to update package lists." $RED
    exit 1
}

# Install GitHub CLI
print_colored "Installing GitHub CLI..." $CYAN
run_command apt install gh -y || {
    print_colored "Failed to install GitHub CLI." $RED
    exit 1
}

# Verify GitHub CLI installation
if command_exists gh; then
    print_colored "GitHub CLI has been successfully installed." $GREEN
else
    print_colored "GitHub CLI installation verification failed." $RED
    exit 1
fi
