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
apt-get install -y pciutils wget || { print_colored "Failed to install required packages." $RED; exit 1; }

# Detect the GPU
gpu_info=$(lspci | grep -i 'vga\|3d\|2d')

# Check if the GPU is NVIDIA or Quadro
if echo "$gpu_info" | grep -qi 'nvidia'; then
    # Extract the GPU model from the lspci output
    gpu_model=$(echo "$gpu_info" | awk -F': ' '{print $3}' | awk '{print $1}')
    print_colored "Detected NVIDIA/Quadro GPU: $gpu_model" $GREEN

    # Download the appropriate NVIDIA driver package
    driver_package=$(wget -qO- https://www.nvidia.com/Download/processFind.aspx?psid=101&pfid=867&osid=36&lid=1&whql=1&lang=en-us&ctk=0 | grep -oP 'NVIDIA-Linux-x86_64-\d+\.\d+\.run')
    wget "https://us.download.nvidia.com/XFree86/Linux-x86_64/$driver_package"

    # Install the NVIDIA driver
    chmod +x "$driver_package"
    "./$driver_package" --dkms --no-kernel-sources
    if [ $? -eq 0 ]; then
        print_colored "NVIDIA/Quadro driver installation completed successfully." $GREEN
    else
        print_colored "NVIDIA/Quadro driver installation failed." $RED
        exit 1
    fi
else
    print_colored "No NVIDIA/Quadro GPU detected." $YELLOW
    exit 0
fi

# Regenerate the kernel initramfs
update-initramfs -u

# Activate the changes for the current user
print_colored "Activating the changes for the current user..." $CYAN
newgrp video

print_colored "Please reboot your system for the changes to take effect." $GREEN