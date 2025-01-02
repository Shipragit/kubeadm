#!/bin/bash
# Author: Shivakumara A

set -euxo pipefail

KUBERNETES_VERSION=v1.32
CRIO_VERSION=v1.32

# Turn off swap setting
sudo swapoff -a

# Enable IPv4 packet forwarding
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

# Install dependencies
sudo apt-get update
sudo apt-get install -y software-properties-common curl gnupg2

# Add the Kubernetes repository
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Add the CRI-O repository
curl -fsSL https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$CRIO_VERSION/xUbuntu_22.04/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$CRIO_VERSION/xUbuntu_22.04/ /" | sudo tee /etc/apt/sources.list.d/cri-o.list

# Install the packages
sudo apt-get update
sudo apt-get install -y cri-o kubelet kubeadm kubectl

# Start CRI-O
sudo systemctl enable crio.service --now

# Initialize Kubernetes Cluster
sudo modprobe br_netfilter
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.bridge.bridge-nf-call-iptables=1
sudo sysctl -w net.bridge.bridge-nf-call-ip6tables=1

# Final setup for Kubernetes
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Initialize the kubelet
sudo systemctl enable --now kubelet
