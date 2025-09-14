#!/bin/bash
set -euxo pipefail

CLUSTER_NAME=${CLUSTER_NAME}
BUCKET_NAME=${BUCKET_NAME}
REGION=${REGION}

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release awscli

# Containerd
swapoff -a || true
sed -i.bak '/ swap / s/^/#/' /etc/fstab || true
modprobe overlay || true
modprobe br_netfilter || true
cat <<EOF | tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
cat <<EOF | tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sysctl --system

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \ 
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update && apt-get install -y containerd.io
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl enable --now containerd
systemctl restart containerd

# Kubernetes packages
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://dl.k8s.io/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# Single control-plane bootstrap via kubeadm
POD_CIDR=${POD_CIDR:-10.244.0.0/16}
sysctl net.ipv4.ip_forward=1

if ! [ -f /etc/kubernetes/admin.conf ]; then
  kubeadm init --pod-network-cidr=${POD_CIDR}

  mkdir -p $HOME/.kube
  cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  chown $(id -u):$(id -g) $HOME/.kube/config

  # Install flannel CNI
  kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

  # Publish worker join command to S3 for workers to consume
  kubeadm token create --print-join-command > /tmp/join.sh
  aws s3 cp /tmp/join.sh s3://${BUCKET_NAME}/${CLUSTER_NAME}/join.sh --region ${REGION}
fi

echo "Control plane bootstrap completed."
