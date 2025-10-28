# EKS Module - Variables

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "vpc_id" {
  description = "VPC ID where EKS cluster will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS nodes"
  type        = list(string)
}

variable "node_instance_types" {
  description = "List of instance types for the EKS node group"
  type        = list(string)
  default     = ["t3.small"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "node_disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = 20
}

variable "enable_cluster_logging" {
  description = "Enable EKS control plane logging"
  type        = bool
  default     = true
}

variable "cluster_log_retention_days" {
  description = "Number of days to retain cluster logs"
  type        = number
  default     = 7
}

# EKS Add-on Versions (for Kubernetes 1.31)
variable "vpc_cni_addon_version" {
  description = "Version of VPC CNI add-on"
  type        = string
  default     = "v1.19.0-eksbuild.1"  # Latest for K8s 1.31
}

variable "coredns_addon_version" {
  description = "Version of CoreDNS add-on"
  type        = string
  default     = "v1.11.3-eksbuild.2"  # Latest for K8s 1.31
}

variable "kube_proxy_addon_version" {
  description = "Version of kube-proxy add-on"
  type        = string
  default     = "v1.31.2-eksbuild.3"  # Compatible with K8s 1.31
}

variable "ebs_csi_addon_version" {
  description = "Version of AWS EBS CSI driver add-on"
  type        = string
  default     = "v1.37.0-eksbuild.1"  # Latest for K8s 1.31
}

variable "tags" {
  description = "Additional tags for EKS resources"
  type        = map(string)
  default     = {}
}
