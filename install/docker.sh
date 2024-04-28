#!/bin/bash

# Color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored text
print_colored() {
    echo -e "${2}${1}${NC}"
}

# Check if the script is being run with root privileges
if [[ $EUID -ne 0 ]]; then
    print_colored "This script must be run as root. Please use 'sudo' or log in as the root user." $RED
    exit 1
fi

# Update package lists
print_colored "Updating package lists..." $BLUE
apt-get update

# Install required packages
print_colored "Installing required packages..." $BLUE
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
print_colored "Adding Docker's official GPG key..." $BLUE
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the stable repository
print_colored "Setting up the stable repository..." $BLUE
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package lists again
print_colored "Updating package lists..." $BLUE
apt-get update

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    print_colored "Docker is already installed. Updating to the latest version..." $YELLOW
    apt-get install -y docker-ce docker-ce-cli containerd.io
else
    # Install the latest version of Docker
    print_colored "Installing the latest version of Docker..." $BLUE
    apt-get install -y docker-ce docker-ce-cli containerd.io
fi

# Add the current user to the docker group
print_colored "Adding the current user to the docker group..." $BLUE
usermod -aG docker $USER

# Get the latest version of Docker Compose
print_colored "Getting the latest version of Docker Compose..." $BLUE
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)

# Download Docker Compose
print_colored "Downloading Docker Compose $COMPOSE_VERSION..." $BLUE
curl -L "https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Apply executable permissions to the Docker Compose binary
print_colored "Applying executable permissions to the Docker Compose binary..." $BLUE
chmod +x /usr/local/bin/docker-compose

# Create a symbolic link for Docker Compose
print_colored "Creating a symbolic link for Docker Compose..." $BLUE
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Print success message
print_colored "Docker and Docker Compose have been successfully installed/updated to the latest version." $GREEN
print_colored "Please log out and log back in for the changes to take effect." $YELLOW