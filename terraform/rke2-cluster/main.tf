provider "lxd" {}

variable "control_plane_count" {
  default = 3
}

variable "worker_count" {
  default = 7
}

resource "lxd_container" "control_planes" {
  count   = var.control_plane_count
  name    = "rke2-cp-${count.index + 1}"
  image   = "ubuntu:24.04"
  profiles = ["default"]
  config = {
    "security.nesting"    = "true"
    "security.privileged" = "true"
  }

  provisioner "remote-exec" {
    inline = [
      "curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=server sh -",
      "systemctl enable rke2-server && systemctl start rke2-server"
    ]
  }
}

resource "lxd_container" "workers" {
  count   = var.worker_count
  name    = "rke2-worker-${count.index + 1}"
  image   = "ubuntu:24.04"
  profiles = ["default"]
  config = {
    "security.nesting"    = "true"
    "security.privileged" = "true"
  }

  provisioner "remote-exec" {
    inline = [
      "curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=agent sh -"
    ]
  }
}

output "control_plane_ips" {
  value = [for c in lxd_container.control_planes : c.ipv4_address]
}

output "worker_ips" {
  value = [for w in lxd_container.workers : w.ipv4_address]
}