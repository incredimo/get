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
 INSTALLING NVIDIA/QUADRO DRIVERS ON LINUX
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
apt-get install -y pciutils lshw wget || { print_colored "Failed to install required packages." $RED; exit 1; }

# Detect NVIDIA or Quadro GPU
if lspci | grep -Eqi 'nvidia|quadro'; then
    print_colored "NVIDIA or Quadro GPU detected. Proceeding with driver installation..." $GREEN

    # Blacklist Nouveau driver if present
    if lsmod | grep -qi "nouveau"; then
        echo "blacklist nouveau" >> /etc/modprobe.d/blacklist-nvidia-nouveau.conf
        print_colored "Blacklisting Nouveau driver..." $YELLOW
        update-initramfs -u
    fi

    # Install the latest NVIDIA driver available in Debian
    print_colored "Installing NVIDIA driver..." $CYAN
    apt-get install -y nvidia-driver || { print_colored "Failed to install NVIDIA driver." $RED; exit 1; }

    # Check if NVIDIA driver is installed and loaded
    if command_exists nvidia-smi; then
        print_colored "NVIDIA driver installation successful." $GREEN
        print_colored "Please reboot your system for the changes to take effect." $GREEN
    else
        print_colored "Failed to install NVIDIA driver." $RED
        exit 1
    fi
else
    print_colored "No NVIDIA or Quadro GPU detected." $YELLOW
fi
