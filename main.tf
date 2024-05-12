module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.10.0"

  cluster_name                   = var.cluster_name
  cluster_version                = var.eks_version

  cluster_endpoint_public_access           = true
  authentication_mode                      = "API_AND_CONFIG_MAP"
  enable_cluster_creator_admin_permissions = true

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

module "eks_addons" {
  source     = "aws-ia/eks-blueprints-addons/aws"
  version    = "1.16.2"
  depends_on = [module.eks]

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  eks_addons = {

    kube-proxy = { most_recent = true }

    vpc-cni = {
      most_recent                 = true
      service_account_role_arn    = module.vpc_cni_irsa_role.iam_role_arn
    }

    coredns = {
      most_recent          = true
      configuration_values = jsonencode({
        nodeSelector = {
          "node.kubernetes.io/role" = "management"
        }
        tolerations = [
          {
            key      = "dedicated"
            operator = "Equal"
            value    = "management"
            effect   = "NoSchedule"
          }
        ]
      })
    }

    aws-ebs-csi-driver = {
      amost_recent             = true
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
      configuration_values     = jsonencode({
        controller = {
          nodeSelector = {
            "node.kubernetes.io/role" = "management"
          }
          tolerations = [
            {
              key      = "dedicated"
              operator = "Equal"
              value    = "management"
              effect   = "NoSchedule"
            }
          ]
        }
      })
    }

  # aws-efs-csi-driver
  # aws-mountpoint-s3-csi-driver
  # aws-guardduty-agent
  # eks-pod-identity-agent = { most_recent = true }
  }
}

module "vpc_cni_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.39.0"

  role_name             = "${var.cluster_name}-vpc-cni"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }
}

module "ebs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.39.0"

  role_name             = "${var.cluster_name}-ebs-csi-controller-sa"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

# module "karpenter" {
#   source = "terraform-aws-modules/eks/aws//modules/karpenter"
#   version = "20.10.0"

#   cluster_name = var.cluster_name

#   create_node_iam_role = false
#   node_iam_role_arn    = module.eks.eks_managed_node_groups[var.management_node_group_name].iam_role_arn
#   create_access_entry  = false
# }