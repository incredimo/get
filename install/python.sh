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
  PYTHON INSTALLATION SCRIPT FOR DEBIAN
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

# Install prerequisites
print_colored "Installing prerequisites..." $CYAN
apt-get install -y software-properties-common curl || { print_colored "Failed to install required packages." $RED; exit 1; }

# Add deadsnakes PPA manually
print_colored "Adding deadsnakes PPA..." $CYAN
curl -fsSL https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x6A755776 | gpg --dearmor -o /usr/share/keyrings/deadsnakes-archive-keyring.gpg || { print_colored "Failed to fetch and add PPA key." $RED; exit 1; }
echo "deb [signed-by=/usr/share/keyrings/deadsnakes-archive-keyring.gpg] http://ppa.launchpad.net/deadsnakes/ppa/ubuntu $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/deadsnakes.list || { print_colored "Failed to add PPA to sources list." $RED; exit 1; }

# Update package lists again
print_colored "Updating package lists after adding PPA..." $CYAN
apt-get update || { print_colored "Failed to update package lists after adding PPA." $RED; exit 1; }

# Install Python
print_colored "Installing Python..." $CYAN
apt-get install -y python3.9 python3.9-venv python3.9-dev || { print_colored "Failed to install Python." $RED; exit 1; }

# Verify Python installation
if command_exists python3.9; then
    print_colored "Python has been successfully installed." $GREEN
    python3.9 --version
else
    print_colored "Python installation verification failed. Please check the installation logs." $RED
    exit 1
fi

# Optional: Set up a virtual environment
read -p "Do you want to set up a virtual environment? (y/n): " setup_venv

if [[ $setup_venv == "y" || $setup_venv == "Y" ]]; then
    read -p "Enter the directory name for the virtual environment: " venv_dir
    python3.9 -m venv "$venv_dir" || { print_colored "Failed to create virtual environment." $RED; exit 1; }
    print_colored "Virtual environment created at ./$venv_dir. Activate it with 'source $venv_dir/bin/activate'." $GREEN
else
    print_colored "Skipping virtual environment setup." $YELLOW
fi

print_colored "Python installation and setup complete." $GREEN
