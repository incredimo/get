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
${NC}"
# Check if the script is being run with root privileges

# Check if the script is being run with root privileges
if [[ $EUID -ne 0 ]]; then
    print_colored "This script must be run as root. Please use 'sudo' or log in as the root user." $RED
    exit 1
fi

# Remove any existing Docker repositories for Ubuntu
print_colored "Removing any existing Docker repositories for Ubuntu..." $CYAN
sed -i '/download.docker.com\/linux\/ubuntu/d' /etc/apt/sources.list /etc/apt/sources.list.d/*.list

# Update package lists
print_colored "Updating package lists..." $CYAN
apt-get update || { print_colored "Failed to update package lists. Please check your internet connection." $RED; exit 1; }

# Install required packages
print_colored "Installing required packages..." $CYAN
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release || { print_colored "Failed to install required packages." $RED; exit 1; }

# Add Docker's official GPG key
print_colored "Adding Docker's official GPG key..." $CYAN
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg || { print_colored "Failed to add Docker's official GPG key." $RED; exit 1; }

# Set up the stable repository for Debian
print_colored "Setting up the stable repository for Debian..." $CYAN
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null || { print_colored "Failed to set up the stable repository for Debian." $RED; exit 1; }



# Update package lists again
print_colored "Updating package lists..." $CYAN
apt-get update || { print_colored "Failed to update package lists. Please check your internet connection." $RED; exit 1; }

# Check if Docker is already installed
if command_exists docker; then
    print_colored "Docker is already installed. Updating to the latest version..." $YELLOW
    apt-get install -y docker-ce docker-ce-cli containerd.io || { print_colored "Failed to update Docker to the latest version." $RED; exit 1; }
else
    # Install the latest version of Docker
    print_colored "Installing the latest version of Docker..." $CYAN
    apt-get install -y docker-ce docker-ce-cli containerd.io || { print_colored "Failed to install Docker." $RED; exit 1; }
fi

# Add the current user to the docker group
print_colored "Adding the current user to the docker group..." $CYAN
usermod -aG docker $USER || { print_colored "Failed to add the current user to the docker group." $RED; exit 1; }

# Get the latest version of Docker Compose
print_colored "Getting the latest version of Docker Compose..." $CYAN
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)

# Download Docker Compose
print_colored "Downloading Docker Compose $COMPOSE_VERSION..." $CYAN
curl -L "https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose || { print_colored "Failed to download Docker Compose." $RED; exit 1; }

# Apply executable permissions to the Docker Compose binary
print_colored "Applying executable permissions to the Docker Compose binary..." $CYAN
chmod +x /usr/local/bin/docker-compose || { print_colored "Failed to apply executable permissions to the Docker Compose binary." $RED; exit 1; }

# Create a symbolic link for Docker Compose
print_colored "Creating a symbolic link for Docker Compose..." $CYAN
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose || { print_colored "Failed to create a symbolic link for Docker Compose." $RED; exit 1; }

# Activate the changes for the current user
print_colored "Activating the changes for the current user..." $CYAN
newgrp docker

# Verify Docker installation
if command_exists docker; then
    print_colored "Docker has been successfully installed/updated to the latest version." $GREEN
else
    print_colored "Docker installation verification failed. Please check the installation logs." $RED
    exit 1
fi

# Verify Docker Compose installation
if command_exists docker-compose; then
    print_colored "Docker Compose has been successfully installed/updated to the latest version." $GREEN
else
    print_colored "Docker Compose installation verification failed. Please check the installation logs." $RED
    exit 1
fi