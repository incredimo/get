# script to automatically install docker and docker compose in debian / ubuntu based systems
# this can be run by calling the following command: curl get.xo.rs/docker | bash

# check admin privileges
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# install docker
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian buster stable"
apt-get update
apt-get install -y docker-ce

# install docker compose (latest version)
echo "Installing docker compose..."
curl -L "$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep browser_download_url | grep docker-compose-Linux-x86_64 | cut -d '"' -f 4)" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose && docker-compose --version && echo "Done!"
