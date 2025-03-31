#!/bin/bash
set -e

# Update & install dependencies
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl wget net-tools vim python3-pip docker.io docker-compose apt-transport-https ca-certificates gnupg lsb-release

# DevStack Setup
sudo useradd -s /bin/bash -d /opt/stack -m stack
echo "stack ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/stack

sudo su - stack <<EOF
  git clone https://opendev.org/openstack/devstack
  cd devstack
  cat > local.conf <<EOL
[[local|localrc]]
ADMIN_PASSWORD=secret
DATABASE_PASSWORD=secret
RABBIT_PASSWORD=secret
SERVICE_PASSWORD=secret
HOST_IP=127.0.0.1
RECLONE=yes
EOL
  ./stack.sh
EOF

# Install Kubernetes (MicroK8s for simplicity)
sudo snap install microk8s --classic
sudo usermod -a -G microk8s vagrant
sudo chown -f -R vagrant ~/.kube

# Enable MicroK8s services
microk8s enable dns storage ingress metallb:10.0.2.200-10.0.2.250

# Install Prometheus and Grafana
microk8s enable prometheus grafana

# Install exporters
sudo apt install -y prometheus-node-exporter

# Optional: Add other exporters (lldp, ethtool, redfish)
# These often require building from source or containerized deployment

# Start services
sudo systemctl enable prometheus-node-exporter
sudo systemctl start prometheus-node-exporter

# Post info
echo "DevStack is installed in /opt/stack/devstack"
echo "Kubernetes available via microk8s"
echo "Grafana default: http://localhost:3000 (admin/admin)"
echo "Prometheus: http://localhost:9090"
echo "Use \`microk8s kubectl\` for K8s commands"

