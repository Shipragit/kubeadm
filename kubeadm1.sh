#!/bin/bash
# Author: Shivakumara A

set -euxo pipefail

KUBERNETES_VERSION=v1.31
CRIO_VERSION=v1.30

# Turn off swap setting
sudo swapoff -a

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system


# Install dependencies
sudo apt-get update
sudo apt-get install -y software-properties-common curl

# Add the Kubernetes repository
curl -fsSL https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/Release.key |
    gpg --dearmor | sudo tee /etc/apt/keyrings/kubernetes-apt-keyring.gpg > /dev/null

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/ /" |
    sudo tee /etc/apt/sources.list.d/kubernetes.list

# Add the CRI-O repository
curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/stable:/$CRIO_VERSION/deb/Release.key |
    gpg --dearmor | sudo tee /etc/apt/keyrings/cri-o-apt-keyring.gpg > /dev/null

echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/stable:/$CRIO_VERSION/deb/ /" |
    sudo tee /etc/apt/sources.list.d/cri-o.list

# Install the packages
sudo apt-get update
sudo apt-get install -y cri-o kubelet kubeadm kubectl

# Start CRI-O
sudo systemctl start crio.service

# Bootstrap a cluster
sudo swapoff -a
sudo modprobe br_netfilter
sudo sysctl -w net.ipv4.ip_forward=1

sudo kubeadm init --apiserver-advertise-address:192.168.29.126 --pod-network-cidr:10.10.0.0/16 --v=5

#cgroup driver
[crio.runtime]
conmon_cgroup = "pod"
cgroup_manager = "cgroupfs"
 
[crio.image]
pause_image="registry.k8s.io/pause:3.6"


# Final setup for Kubernetes
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Add the Kubernetes repository key again if necessary
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable --now kubelet

