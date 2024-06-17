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
INSTALLING RUST ON DEBIAN
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

# Check if curl is installed, if not install it
print_colored "Checking if curl is installed..." $CYAN
if ! command_exists curl; then
    print_colored "curl not found. Installing curl..." $YELLOW
    run_command apt update && run_command apt-get install curl -y || {
        print_colored "Failed to install curl. Please check your internet connection." $RED
        exit 1
    }
else
    print_colored "curl is already installed." $GREEN
fi

# Download and run Rust installation script
print_colored "Downloading and running Rust installation script..." $CYAN
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || {
    print_colored "Failed to download and run Rust installation script." $RED
    exit 1
}

# Source the environment variables
print_colored "Sourcing environment variables..." $CYAN
source $HOME/.cargo/env || {
    print_colored "Failed to source environment variables." $RED
    exit 1
}

# Verify Rust installation
print_colored "Verifying Rust installation..." $CYAN
if command_exists rustc; then
    print_colored "Rust has been successfully installed." $GREEN
    rustc --version
else
    print_colored "Rust installation verification failed." $RED
    exit 1
fi
