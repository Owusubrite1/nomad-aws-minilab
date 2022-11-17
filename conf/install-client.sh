#!/bin/bash
# 
# user-data script for deploying Nomad on Amazon Linux 2
# 
# Using the user-data / cloud init ensures we don't run twice
#  

# Update system and install dependencies
sudo yum update -y
sudo install unzip curl vim jq -y
# make an archive folder to move old binaries into
if [ ! -d /tmp/archive ]; then
  sudo mkdir /tmp/archive/
fi

# Install docker
sudo amazon-linux-extras install docker -y
sudo systemctl restart docker

# Set up volumes
sudo mkdir /data /data/mysql /data/certs /data/prometheus /data/templates
sudo chown root -R /data

# Install Nomad
NOMAD_VERSION=1.4.0
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
sudo curl https://raw.githubusercontent.com/Owusubrite1/nomad-in-aws/master/conf/nomad/client.hcl -o /tmp/nomad/client.hcl
sudo cp /tmp/nomad/client.hcl /etc/nomad.d/client.hcl

# Install Consul
CONSUL_VERSION=1.13.2

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
sudo curl https://raw.githubusercontent.com/Owusubrite1/nomad-in-aws/master/conf/consul/client.hcl -o /tmp/consul/client.hcl
sudo cp /tmp/consul/client.hcl /etc/consul.d/client.hcl


for bin in cfssl cfssl-certinfo cfssljson
do
  echo "$bin Install Beginning..."
  if [ ! -f /tmp/${bin} ]; then
    curl -sSL https://pkg.cfssl.org/R1.2/${bin}_linux-amd64 > /tmp/${bin}
  fi
  if [ ! -f /usr/local/bin/${bin} ]; then
    sudo install /tmp/${bin} /usr/local/bin/${bin}
  fi
done
cat /root/.bashrc | grep  "complete -C /usr/bin/nomad nomad"
retval=$?
if [ $retval -eq 1 ]; then
  nomad -autocomplete-install
fi

# Install Ansible for config management
sudo amazon-linux-extras install ansible2 -y

# Form Consul Cluster
ps -C consul
retval=$?
if [ $retval -eq 0 ]; then
  sudo killall consul
fi
#sudo nohup consul agent --config-file /etc/consul.d/client.hcl >$HOME/consul.log &

# Form Nomad Cluster
ps -C nomad
retval=$?
if [ $retval -eq 0 ]; then
  sudo killall nomad
fi
# sudo nohup nomad agent -config /etc/nomad.d/client.hcl >$HOME/nomad.log &

# Configure Nomad Autostart
sudo curl https://raw.githubusercontent.com/Owusubrite1/nomad-in-aws/master/conf/nomad/nomad.service -o /tmp/nomad/nomad.service
sudo cp /tmp/nomad/nomad.service /etc/systemd/system/nomad.service
sudo systemctl enable nomad

# sudo systemctl start nomad

# Configure Consul Autostart
sudo curl https://raw.githubusercontent.com/Owusubrite1/nomad-in-aws/master/conf/consul/consul-client.service -o /tmp/consul/consul.service
sudo cp /tmp/consul/consul.service /etc/systemd/system/consul.service
sudo systemctl enable consul

# sudo systemctl start consul

# Configure Docker Autostart
sudo systemctl enable docker

# Bootstrap Nomad and Consul ACL environment

# Write anonymous policy file 

sudo tee -a /tmp/anonymous.policy <<EOF
namespace "*" {
  policy       = "write"
  capabilities = ["alloc-node-exec"]
}

agent {
  policy = "write"
}

operator {
  policy = "write"
}

quota {
  policy = "write"
}

node {
  policy = "write"
}

host_volume "*" {
  policy = "write"
}
EOF

