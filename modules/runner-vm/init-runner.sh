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

# Install packages which the workflows expect
sudo yum install -y git

# Create cron script to automatically prune unused images
echo "Creating Docker images prune cron script..."
echo "docker image prune -a --force --filter \"until=24h\"" | sudo tee /etc/cron.daily/prune-docker
sudo chmod a+x /etc/cron.daily/prune-docker

# Create user for GitHub Runner
echo "Creating github-runner user..."
sudo groupadd -g 8000 github-admins
sudo adduser --uid 8000 github-runner

sudo usermod -a -G wheel github-runner
sudo usermod -a -G github-admins github-runner
sudo usermod -a -G docker github-runner

sudo usermod -g github-admins github-runner # set the github-admins as the primary group

# Add the Azure SSH user to the admin and docker groups
CLOUD_USER=$(cat /etc/passwd | grep ":1000:" | cut -d ':' -f 1)
sudo usermod -a -G github-admins "$CLOUD_USER"
sudo usermod -a -G docker "$CLOUD_USER"
sudo usermod -a -G wheel "$CLOUD_USER"

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
sudo ./bin/installdependencies.sh

echo "Configuring runner..."
sudo RUNNER_ALLOW_RUNASROOT=1 ./config.sh --url "${github_org_url}" --unattended --replace --token "${github_runner_token}"

sudo chgrp -R github-admins /opt/actions-runner
sudo chown -R github-runner /opt/actions-runner

sudo chmod -R g+rw /opt/actions-runner

echo "Installing runner as a service..."
sudo ./svc.sh install github-runner

echo "Downloading docker wrapper script..."
curl -o /tmp/docker-wrapper "https://raw.githubusercontent.com/xanantis/docker-file-ownership-fix/master/bin/docker"
sudo chmod a+x /tmp/docker-wrapper
sudo mv /usr/bin/docker /usr/bin/docker___
sudo mv /tmp/docker-wrapper /usr/bin/docker

echo "Updating github runner environment variables..."
mkdir /etc/systemd/system/actions.runner.${github_org_name}.$(hostname).service.d
echo "[Service]" > /etc/systemd/system/actions.runner.${github_org_name}.$(hostname).service.d/docker-user.conf
echo "Environment=\"DOCKER_USER_OPTION=\$UID:\$GID\"" >> /etc/systemd/system/actions.runner.${github_org_name}.$(hostname).service.d/docker-user.conf
sudo systemctl daemon-reload

echo "Starting the runner..."
sudo ./svc.sh start

echo "Done :)"