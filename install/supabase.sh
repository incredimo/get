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
███████╗██╗   ██╗██████╗  █████╗ ██████╗  █████╗ ███████╗███████╗
██╔════╝██║   ██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔════╝
███████╗██║   ██║██████╔╝███████║██████╔╝███████║███████╗█████╗  
╚════██║██║   ██║██╔═══╝ ██╔══██║██╔══██╗██╔══██║╚════██║██╔══╝  
███████║╚██████╔╝██║     ██║  ██║██████╔╝██║  ██║███████║███████╗
╚══════╝ ╚═════╝ ╚═╝     ╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝
-------------------------------------------------------------
SELF-HOSTED SUPABASE INSTALLATION SCRIPT
-------------------------------------------------------------${NC}"

# Check if required commands exist
print_colored "Checking prerequisites..." $CYAN

for cmd in git docker docker-compose curl; do
    if ! command_exists $cmd; then
        print_colored "Error: $cmd is not installed." $RED
        print_colored "Please install $cmd and try again." $YELLOW
        exit 1
    fi
done

# Create project directory
PROJECT_DIR="supabase-project"
print_colored "Creating project directory..." $CYAN
mkdir -p $PROJECT_DIR

# Clone Supabase repository
print_colored "Cloning Supabase repository..." $CYAN
git clone --depth 1 https://github.com/supabase/supabase || {
    print_colored "Failed to clone Supabase repository." $RED
    exit 1
}

# Copy configuration files
print_colored "Copying configuration files..." $CYAN
cp -rf supabase/docker/* $PROJECT_DIR || {
    print_colored "Failed to copy Docker files." $RED
    exit 1
}

# Copy example env file
cp supabase/docker/.env.example $PROJECT_DIR/.env || {
    print_colored "Failed to copy environment file." $RED
    exit 1
}

# Generate secure secrets
print_colored "Generating secure secrets..." $CYAN
JWT_SECRET=$(openssl rand -base64 32)
ANON_KEY=$(openssl rand -base64 32)
SERVICE_ROLE_KEY=$(openssl rand -base64 32)
POSTGRES_PASSWORD=$(openssl rand -base64 32)
DASHBOARD_USERNAME="admin"
DASHBOARD_PASSWORD=$(openssl rand -base64 16)

# Update environment variables
cd $PROJECT_DIR
sed -i "s/your-super-secret-jwt-token-with-at-least-32-characters-long/$JWT_SECRET/g" .env
sed -i "s/eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9/$ANON_KEY/g" .env
sed -i "s/eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9/$SERVICE_ROLE_KEY/g" .env
sed -i "s/your-super-secret-and-long-postgres-password/$POSTGRES_PASSWORD/g" .env
sed -i "s/supabase/$DASHBOARD_USERNAME/g" .env
sed -i "s/this_password_is_insecure_and_should_be_updated/$DASHBOARD_PASSWORD/g" .env

# Pull Docker images
print_colored "Pulling Docker images..." $CYAN
docker compose pull || {
    print_colored "Failed to pull Docker images." $RED
    exit 1
}

# Start services
print_colored "Starting Supabase services..." $CYAN
docker compose up -d || {
    print_colored "Failed to start Supabase services." $RED
    exit 1
}

# Wait for services to be healthy
print_colored "Waiting for services to be ready..." $CYAN
sleep 10

# Check service status
print_colored "Checking service status..." $CYAN
docker compose ps

# Print success message and credentials
print_colored "\nSupabase has been successfully installed!" $GREEN
print_colored "\nImportant Credentials (SAVE THESE SECURELY):" $YELLOW
echo "------------------------------------"
print_colored "Dashboard URL: http://localhost:8000" $CYAN
print_colored "Dashboard Username: $DASHBOARD_USERNAME" $CYAN
print_colored "Dashboard Password: $DASHBOARD_PASSWORD" $CYAN
echo "------------------------------------"
print_colored "Database URL: postgresql://postgres:$POSTGRES_PASSWORD@localhost:5432/postgres" $CYAN
print_colored "API URL: http://localhost:8000" $CYAN
echo "------------------------------------"

# Print management commands
print_colored "\nTo manage your Supabase installation:" $CYAN
print_colored "Start services: docker compose up -d" $CYAN
print_colored "Stop services: docker compose down" $CYAN
print_colored "View logs: docker compose logs" $CYAN
print_colored "Restart services: docker compose restart" $CYAN
print_colored "Update services: docker compose pull && docker compose up -d" $CYAN

print_colored "\nInstallation complete! Visit http://localhost:8000 to access your Supabase dashboard." $GREEN