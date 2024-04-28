#!/bin/bash

# Check if the script is running as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Check the distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DIST=$ID
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    DIST=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/debian_version ]; then
    DIST=Debian
    VER=$(cat /etc/debian_version)
else
    echo "Unable to determine distribution" 1>&2
    exit 1
fi

# Check the package manager
case "$DIST" in
    Ubuntu|Debian|Proxmox)
        PKG_MGR="apt-get -y"
        ;;
    *)
        echo "Unsupported distribution: $DIST" 1>&2
        exit 1
        ;;
esac

# Install prerequisites
echo "Installing prerequisites..."
$PKG_MGR update
$PKG_MGR install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    software-properties-common

# Add Docker's official GPG key
echo "Adding Docker's official GPG key..."
curl -fsSL https://download.docker.com/linux/$DIST/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the stable repository
echo "Setting up the stable repository..."
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$DIST \
    $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
$PKG_MGR update

# Install Docker Engine
echo "Installing Docker Engine..."
$PKG_MGR install docker-ce docker-ce-cli containerd.io

# Install Docker Compose
echo "Installing Docker Compose..."
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4)
curl -L "https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Add Docker to the user's PATH (for the current user)
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
source ~/.bashrc

# Enable and start Docker service
echo "Enabling and starting Docker service..."
systemctl enable docker.service
systemctl start docker.service

# Enable Docker service to start on system boot
echo "Configuring Docker to start on system boot..."
systemctl enable docker.service

echo "Docker and Docker Compose have been installed successfully!"