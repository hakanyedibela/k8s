output "kubeconfig_info" {
  value = <<EOT
To access your cluster:
1. Pull the kubeconfig from the first control plane:
   lxc file pull rke2-cp-1/etc/rancher/rke2/rke2.yaml kubeconfig.yaml
2. Edit the 'server:' line to use the IP of rke2-cp-1:
   server: https://<IP>:6443
3. Run:
   KUBECONFIG=./kubeconfig.yaml kubectl get nodes
EOT
}