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
INSTALLING POCKETBASE ON DEBIAN
---------------------------------------------
${NC}"


# Update package lists
print_colored "Updating package lists..." $CYAN
run_command apt-get update || {
    print_colored "Failed to update package lists. Please check your internet connection." $RED
    exit 1
}

# Install required packages
print_colored "Installing required packages..." $CYAN
run_command apt-get install -y wget unzip || {
    print_colored "Failed to install required packages." $RED
    exit 1
}

# Check if curl is available
if command_exists curl; then
    DOWNLOAD_COMMAND="curl -sLO"
    DOWNLOAD_TOOL="curl"
else
    DOWNLOAD_COMMAND="wget -qO"
    DOWNLOAD_TOOL="wget"
fi

# Get the latest PocketBase release version
LATEST_RELEASE=$(${DOWNLOAD_TOOL} -qO- https://github.com/pocketbase/pocketbase/releases/latest | grep -oP 'tag/v\K\d+\.\d+\.\d+')

# Download PocketBase
print_colored "Downloading PocketBase version $LATEST_RELEASE..." $CYAN
DOWNLOAD_URL="https://github.com/pocketbase/pocketbase/releases/download/v$LATEST_RELEASE/pocketbase_${LATEST_RELEASE}_linux_amd64.zip"
${DOWNLOAD_COMMAND} "$DOWNLOAD_URL" || {
    print_colored "Failed to download PocketBase." $RED
    exit 1
}

# Unzip PocketBase
print_colored "Unzipping PocketBase..." $CYAN
unzip -o pocketbase_${LATEST_RELEASE}_linux_amd64.zip -d /usr/local/bin/ || {
    print_colored "Failed to extract PocketBase." $RED
    exit 1
}

# Clean up the zip file
rm pocketbase_${LATEST_RELEASE}_linux_amd64.zip

# Make PocketBase executable
print_colored "Making PocketBase executable..." $CYAN
run_command chmod +x /usr/local/bin/pocketbase || {
    print_colored "Failed to make PocketBase executable." $RED
    exit 1
}

# Create PocketBase systemd service file
print_colored "Creating PocketBase systemd service file..." $CYAN
SERVICE_FILE="/etc/systemd/system/pocketbase.service"
run_command bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=PocketBase service
After=network.target

[Service]
ExecStart=/usr/local/bin/pocketbase serve --dir /var/lib/pocketbase
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start PocketBase service
print_colored "Reloading systemd daemon, enabling and starting PocketBase service..." $CYAN
run_command systemctl daemon-reload
run_command systemctl enable pocketbase.service
run_command systemctl start pocketbase.service

# Verify PocketBase installation
if command_exists pocketbase; then
    print_colored "PocketBase has been successfully installed and started as a systemd service." $GREEN
else
    print_colored "PocketBase installation verification failed. Please check the installation logs." $RED
    exit 1
fi

# Show PocketBase directories
print_colored "PocketBase Directories:" $CYAN
print_colored "Database Directory: /var/lib/pocketbase/data" $CYAN
print_colored "Config Directory: /var/lib/pocketbase/config" $CYAN

# Display service management instructions
print_colored "To manage the PocketBase service:" $CYAN
print_colored "Start the service: sudo systemctl start pocketbase" $CYAN
print_colored "Stop the service: sudo systemctl stop pocketbase" $CYAN
print_colored "Restart the service: sudo systemctl restart pocketbase" $CYAN
print_colored "Check status: sudo systemctl status pocketbase" $CYAN
print_colored "Installation complete. PocketBase is running as a systemd service." $GREEN