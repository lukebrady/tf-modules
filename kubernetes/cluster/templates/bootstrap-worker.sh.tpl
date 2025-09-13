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
systemctl enable --now containerd

# Kubernetes packages
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://dl.k8s.io/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# Wait for join script from S3
mkdir -p /opt/kthw
JOIN_PATH=/opt/kthw/join.sh
until aws s3 cp s3://${BUCKET_NAME}/${CLUSTER_NAME}/join.sh ${JOIN_PATH} --region ${REGION}; do
  echo "Waiting for join.sh in s3://${BUCKET_NAME}/${CLUSTER_NAME}/..."
  sleep 10
done
chmod +x ${JOIN_PATH}
bash ${JOIN_PATH}

echo "Worker joined cluster."
