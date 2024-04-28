#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Check if the script is running as root
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}This script must be run as root${NC}" 1>&2
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
elif [ -f /etc/redhat-release ]; then
    DIST=$(sed 's/\\.*$//' /etc/redhat-release)
    VER=$(sed 's/.*release\ //' /etc/redhat-release | sed 's/\..*$//')
else
    echo -e "${RED}Unable to determine distribution${NC}" 1>&2
    exit 1
fi

# Check the package manager
case "$DIST" in
    Ubuntu|Debian)
        PKG_MGR="apt-get -y"
        ;;
    CentOS|RedHatEnterpriseServer|RedHatEnterpriseClient)
        PKG_MGR="yum -y"
        ;;
    *)
        echo -e "${RED}Unsupported distribution: $DIST${NC}" 1>&2
        exit 1
        ;;
esac

# Install prerequisites
echo -e "${GREEN}Installing prerequisites...${NC}"
case "$DIST" in
    Ubuntu|Debian)
        $PKG_MGR update
        $PKG_MGR install \
            apt-transport-https \
            ca-certificates \
            curl \
            gnupg2 \
            software-properties-common
        ;;
    CentOS|RedHatEnterpriseServer|RedHatEnterpriseClient)
        $PKG_MGR install -y yum-utils
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        ;;
esac

# Add Docker's official GPG key
echo -e "${GREEN}Adding Docker's official GPG key...${NC}"
curl -fsSL https://download.docker.com/linux/$DIST/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the stable repository
echo -e "${GREEN}Setting up the stable repository...${NC}"
case "$DIST" in
    Ubuntu|Debian)
        echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$DIST \
            $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
        $PKG_MGR update
        ;;
esac

# Install Docker Engine
echo -e "${GREEN}Installing Docker Engine...${NC}"
case "$DIST" in
    Ubuntu|Debian)
        $PKG_MGR install docker-ce docker-ce-cli containerd.io
        ;;
    CentOS|RedHatEnterpriseServer|RedHatEnterpriseClient)
        $PKG_MGR install docker-ce docker-ce-cli containerd.io
        ;;
esac

# Install Docker Compose
echo -e "${GREEN}Installing Docker Compose...${NC}"
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4)
curl -L "https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Add Docker to the user's PATH (for the current user)
echo -e "${YELLOW}Adding Docker to the user's PATH...${NC}"
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
source ~/.bashrc

# Enable and start Docker service
echo -e "${GREEN}Enabling and starting Docker service...${NC}"
case "$DIST" in
    Ubuntu|Debian)
        systemctl enable docker.service
        systemctl start docker.service
        ;;
    CentOS|RedHatEnterpriseServer|RedHatEnterpriseClient)
        systemctl enable docker.service
        systemctl start docker.service
        ;;
esac

# Enable Docker service to start on system boot
echo -e "${GREEN}Configuring Docker to start on system boot...${NC}"
systemctl enable docker.service

echo -e "${GREEN}Docker and Docker Compose have been installed successfully!${NC}"