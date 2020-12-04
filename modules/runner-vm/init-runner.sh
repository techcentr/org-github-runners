#!/usr/bin/env bash

echo "Upgrading yum packages..."
sudo yum upgrade -y

# Install Docker
echo "Installing Docker..."
sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine

sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io
sudo systemctl start docker

# Create user for GitHub Runner
echo "Creating github-runner user..."
sudo groupadd github-admins
sudo adduser github-runner
sudo usermod -a -G wheel github-runner
sudo usermod -a -G github-admins github-runner

CLOUD_USER=$(cat /etc/passwd | grep ":1000:" | cut -d ':' -f 1)
sudo usermod -a -G github-admins "$CLOUD_USER"

# Install GitHub Runner
echo "Creating /opt/actions-runner directory..."
sudo mkdir -p /opt/actions-runner
sudo chgrp github-admins /opt/actions-runner
sudo chmod 770 /opt/actions-runner

cd /opt/actions-runner

echo "Downloading runner..."
curl -O -L https://github.com/actions/runner/releases/download/v2.274.2/actions-runner-linux-x64-2.274.2.tar.gz
tar xzf ./actions-runner-linux-x64-2.274.2.tar.gz

echo "Installing dependencies..."
./bin/installdependencies.sh

echo "Configuring runner..."
export RUNNER_ALLOW_RUNASROOT=1
./config.sh --url "${github_org_url}" --unattended --replace --token "${github_runner_token}"

sudo chgrp -R github-admins /opt/actions-runner
sudo chmod g+rw /opt/actions-runner/_diag
sudo chmod g+r /opt/actions-runner/.credentials_rsaparams

echo "Installing runner as a service..."
sudo ./svc.sh install github-runner
sudo ./svc.sh start