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
INSTALLING GO ON DEBIAN
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

# Check if tar is installed, if not install it
print_colored "Checking if tar is installed..." $CYAN
if ! command_exists tar; then
    print_colored "tar not found. Installing tar..." $YELLOW
    run_command apt update && run_command apt-get install tar -y || {
        print_colored "Failed to install tar. Please check your internet connection." $RED
        exit 1
    }
else
    print_colored "tar is already installed." $GREEN
fi

# Download Go tarball
print_colored "Downloading Go 1.22.4 tarball..." $CYAN
wget https://go.dev/dl/go1.22.4.linux-amd64.tar.gz || {
    print_colored "Failed to download Go tarball." $RED
    exit 1
}

# Remove any previous Go installation
print_colored "Removing any previous Go installation..." $CYAN
run_command rm -rf /usr/local/go || {
    print_colored "Failed to remove previous Go installation." $RED
    exit 1
}

# Extract Go tarball to /usr/local
print_colored "Extracting Go tarball to /usr/local..." $CYAN
run_command tar -C /usr/local -xzf go1.22.4.linux-amd64.tar.gz || {
    print_colored "Failed to extract Go tarball." $RED
    exit 1
}

# Cleanup downloaded tarball
print_colored "Cleaning up downloaded tarball..." $CYAN
rm go1.22.4.linux-amd64.tar.gz || {
    print_colored "Failed to remove downloaded tarball." $RED
    exit 1
}

# Add Go to PATH
print_colored "Adding Go to PATH..." $CYAN
if ! grep -q "/usr/local/go/bin" ~/.profile; then
    echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.profile
    source ~/.profile
fi

# Verify Go installation
print_colored "Verifying Go installation..." $CYAN
if command_exists go; then
    print_colored "Go 1.22.4 has been successfully installed." $GREEN
    go version
else
    print_colored "Go installation verification failed." $RED
    exit 1
fi
