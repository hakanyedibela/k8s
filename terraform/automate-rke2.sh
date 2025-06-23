#!/bin/bash
# RKE2 + LXD Terraform Automation Script

set -e

CONTROL_PLANES=3
WORKERS=7
RKE2_VERSION="v1.29.1+rke2r1"

# Step 1: Terraform Apply
cd rke2-cluster
terraform init
terraform apply -auto-approve \
  -var="control_plane_count=$CONTROL_PLANES" \
  -var="worker_count=$WORKERS"

# Get IPs of control plane and workers
MASTER_IP=$(lxc list rke2-cp-1 -c 4 | awk '!/IPV4/{ if ( $2 ~ /^[0-9]/ ) print $2 }')
TOKEN=$(lxc exec rke2-cp-1 -- cat /var/lib/rancher/rke2/server/node-token)

# Step 2: Join other control planes
for i in $(seq 2 $CONTROL_PLANES); do
  lxc exec rke2-cp-$i -- bash -c "\
    curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=server INSTALL_RKE2_VERSION=$RKE2_VERSION sh - && \
    mkdir -p /etc/rancher/rke2 && \
    echo 'server: https://$MASTER_IP:9345' > /etc/rancher/rke2/config.yaml && \
    echo 'token: $TOKEN' >> /etc/rancher/rke2/config.yaml && \
    systemctl enable rke2-server && systemctl start rke2-server"
done

# Step 3: Join worker nodes
for i in $(seq 1 $WORKERS); do
  lxc exec rke2-worker-$i -- bash -c "\
    curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=agent INSTALL_RKE2_VERSION=$RKE2_VERSION sh - && \
    mkdir -p /etc/rancher/rke2 && \
    echo 'server: https://$MASTER_IP:9345' > /etc/rancher/rke2/config.yaml && \
    echo 'token: $TOKEN' >> /etc/rancher/rke2/config.yaml && \
    systemctl enable rke2-agent && systemctl start rke2-agent"
done

# Step 4: Pull kubeconfig to host
lxc file pull rke2-cp-1/etc/rancher/rke2/rke2.yaml kubeconfig.yaml
sed -i "s/127.0.0.1/$MASTER_IP/g" kubeconfig.yaml

echo "\n✅ RKE2 cluster deployed successfully!\n"
echo "To access your cluster:"
echo "export KUBECONFIG=./kubeconfig.yaml"
echo "kubectl get nodes"

echo "\nApplying Calico CNI plugin..."
kubectl --kubeconfig=./kubeconfig.yaml apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.2/manifests/calico.yaml

echo "✅ Calico applied. Cluster ready."
