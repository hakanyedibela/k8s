# k8s

### Install lxd community provider

```SHELL
git clone https://github.com/sl1pm4t/terraform-provider-lxd.git
cd terraform-provider-lxd
make install
```


Common Causes & Fixes

## 1. Firewall blocking port 6443

On the control plane node, ensure port 6443 is open:
```SHELL
  sudo ufw allow 6443/tcp
```
or with firewalld:
```SHELL
sudo firewall-cmd --permanent --add-port=6443/tcp && sudo firewall-cmd --reload
```

## 2. Test connectivity from the joining node

From the worker node
```SHELL  
curl -k https://<control-plane-ip>:6443/healthz
```
or
```SHELL
nc -zv <control-plane-ip> 6443
```

## 3. Verify the API server is running on the control plane

On the control plane
```SHELL
sudo systemctl status kubelet
kubectl get pods -n kube-system | grep apiserver
```
  
## 4. Check if the token has expired

Join tokens expire after 24 hours by default. Generate a new one on the control plane:
```SHELL
kubeadm token create --print-join-command
```
  
## 5. Cloud provider / security group

If <control-plane-ip> is a cloud VM (like a public IP), check that cloud security group / firewall rules allow inbound TCP 6443 from the worker node's IP.


