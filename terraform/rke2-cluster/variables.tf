variable "control_plane_count" {
  description = "Number of RKE2 control plane nodes"
  type        = number
  default     = 3
}

variable "worker_count" {
  description = "Number of RKE2 worker nodes"
  type        = number
  default     = 7
}