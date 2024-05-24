module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.11.1"

  cluster_name    = var.cluster_name
  cluster_version = var.eks_version

  cluster_endpoint_public_access = true
  authentication_mode            = "API"

  access_entries = {
    clusterAdmin = {
      principal_arn = "arn:aws:iam::${var.aws_account_id}:role/${var.aws_assume_role}"
      policy_associations = {
        clusterAdmin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  vpc_id                   = data.aws_vpc.vpc.id
  subnet_ids               = data.aws_subnets.cluster_private_subnets.ids
  control_plane_subnet_ids = data.aws_subnets.cluster_intra_subnets.ids

  cluster_enabled_log_types = var.enable_log_types
  create_kms_key            = true

  # For longer cluster names using the prefix goes over 38 char limit
  iam_role_use_name_prefix = false

  eks_managed_node_group_defaults = {
    version              = var.eks_version
    force_update_version = true
    enable_monitoring    = true
  }

  eks_managed_node_groups = {
    # dedicated mgmt node group, other node groups managed by karpenter
    (var.management_node_group_name) = {
      ami_type       = var.management_node_group_ami_type
      instance_types = var.management_node_group_instance_types
      capacity_type  = var.management_node_group_capacity_type
      min_size       = var.management_node_group_min_size
      max_size       = var.management_node_group_max_size
      desired_size   = var.management_node_group_desired_size
      disk_size      = var.management_node_group_disk_size
      labels = {
        "nodegroup"               = var.management_node_group_name
        "node.kubernetes.io/role" = var.management_node_group_role
        "karpenter.sh/controller" = "true"
      }
      taints = {
        dedicated = {
          key    = "dedicated"
          value  = var.management_node_group_role
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

}

output "cluster_url" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "cluster_oidc_issuer_url" {
  value = module.eks.cluster_oidc_issuer_url
}

output "cluster_public_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}
