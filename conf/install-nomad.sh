#!/bin/bash


# Docker
echo "Installing Docker"
sudo apt update -y
sudo apt-get install apt-transport-https ca-certificates curl gnupg lsb-release -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install docker-ce docker-ce-cli containerd.io -y
sudo docker swarm leave --force
sudo apt install awscli -y
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install consul -y
sudo usermod -aG docker ubuntu

sudo apt-get install -y unzip

# Configure Docker Autostart
sudo systemctl enable docker

# Consul
echo "Installing Consul"
CONSUL_VERSION=1.11.4

sudo curl -sSL https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip > consul.zip
if [ ! -d consul ]; then
  sudo unzip consul.zip
fi
if [ ! -f /usr/bin/consul ]; then
  sudo install consul /usr/bin/consul
fi
if [ -f /tmp/archive/consul ]; then
  sudo rm /tmp/archive/consul
fi
sudo mv /tmp/consul /tmp/archive/consul
sudo mkdir -p /etc/consul.d
sudo chmod a+w /etc/consul.d

# Consul config file copy
sudo mkdir -p /tmp/consul
sudo curl https://raw.githubusercontent.com/Owusubrite1/nomad-aws/master/conf/nomad/client.hcl -o /tmp/consul/client.hcl
sudo cp /tmp/consul/client.hcl /etc/consul.d/client.hcl

# Configure Consul Autostart
sudo curl https://raw.githubusercontent.com/Owusubrite1/nomad-in-aws/master/conf/consul/consul-client.service -o /tmp/consul/consul.service
sudo cp /tmp/consul/consul.service /etc/systemd/system/consul.service
sudo systemctl enable consul

# Install Nomad
echo "Installing Nomad"
NOMAD_VERSION=1.2.6
sudo curl -sSL https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip -o nomad.zip
if [ ! -d nomad ]; then
  sudo unzip nomad.zip
fi
if [ ! -f /usr/bin/nomad ]; then
  sudo install nomad /usr/bin/nomad
fi
if [ -f /tmp/archive/nomad ]; then
  sudo rm /tmp/archive/nomad
fi
sudo mv /tmp/nomad /tmp/archive/nomad
sudo mkdir -p /etc/nomad.d
sudo chmod a+w /etc/nomad.d

# Nomad config file copy
sudo mkdir -p /tmp/nomad
sudo curl https://raw.githubusercontent.com/Owusubrite1/nomad-in-aws/master/conf/nomad/server.hcl -o /tmp/nomad/server.hcl
sudo cp /tmp/nomad/server.hcl /etc/nomad.d/server.hcl

# Configure Nomad Autostart
sudo curl https://raw.githubusercontent.com/Owusubrite1/nomad-in-aws/master/conf/nomad/nomad.service -o /tmp/nomad/nomad.service
sudo cp /tmp/nomad/nomad.service /etc/systemd/system/nomad.service
sudo systemctl enable nomad