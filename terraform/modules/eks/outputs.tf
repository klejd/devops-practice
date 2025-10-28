# EKS Module - Outputs

output "cluster_id" {
  description = "The name/id of the EKS cluster"
  value       = aws_eks_cluster.main.id
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "The Kubernetes server version for the cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.cluster.id
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "node_iam_role_arn" {
  description = "IAM role ARN of the EKS node group"
  value       = aws_iam_role.node.arn
}

output "node_iam_role_name" {
  description = "IAM role name of the EKS node group"
  value       = aws_iam_role.node.name
}

output "node_group_id" {
  description = "EKS node group ID"
  value       = aws_eks_node_group.main.id
}

output "node_group_status" {
  description = "Status of the EKS node group"
  value       = aws_eks_node_group.main.status
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC Provider for EKS"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "cluster_platform_version" {
  description = "The platform version for the cluster"
  value       = aws_eks_cluster.main.platform_version
}

# Add-on Outputs
output "vpc_cni_addon_version" {
  description = "Version of VPC CNI add-on installed"
  value       = aws_eks_addon.vpc_cni.addon_version
}

output "coredns_addon_version" {
  description = "Version of CoreDNS add-on installed"
  value       = aws_eks_addon.coredns.addon_version
}

output "kube_proxy_addon_version" {
  description = "Version of kube-proxy add-on installed"
  value       = aws_eks_addon.kube_proxy.addon_version
}

output "ebs_csi_addon_version" {
  description = "Version of EBS CSI driver add-on installed"
  value       = aws_eks_addon.ebs_csi_driver.addon_version
}

# AWS Load Balancer Controller Outputs
output "aws_load_balancer_controller_role_arn" {
  description = "ARN of IAM role for AWS Load Balancer Controller"
  value       = aws_iam_role.aws_load_balancer_controller.arn
}

output "aws_load_balancer_controller_role_name" {
  description = "Name of IAM role for AWS Load Balancer Controller"
  value       = aws_iam_role.aws_load_balancer_controller.name
}
