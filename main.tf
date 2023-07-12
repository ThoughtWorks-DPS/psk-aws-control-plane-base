#tfsec:ignore:aws-eks-no-public-cluster-access
#tfsec:ignore:aws-eks-no-public-cluster-access-to-cidr
#tfsec:ignore:aws-ec2-no-public-egress-sgr
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.15.3"

  cluster_name                   = var.instance_name
  cluster_version                = var.eks_version
  cluster_endpoint_public_access = true
  cluster_enabled_log_types      = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_id     = data.aws_vpc.vpc.id
  subnet_ids = data.aws_subnets.cluster_private_subnets.ids

  manage_aws_auth_configmap = true
  create_kms_key            = true
  #aws_auth_roles = var.aws_auth_roles


  #   cluster_encryption_config = {
  #     provider_key_arn = aws_kms_key.cluster_encyption_key.arn
  #     resources        = ["secrets"]
  #   }

  # For some environments prefix length went over 38 char limit
  iam_role_use_name_prefix = false

  cluster_addons = {

    kube-proxy = {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }

    coredns = {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }

    vpc-cni = {
      most_recent              = true
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.vpc_cni_irsa_role.iam_role_arn
    }

    aws-ebs-csi-driver = {
      most_recent              = true
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
  }

  eks_managed_node_group_defaults = {
    force_update_version = true
    enable_monitoring    = true
  }

  eks_managed_node_groups = {
    # dedicated mgmt node group, other node groups managed by karpenter
    (var.management_node_group_name) = {
      ami_type       = var.management_node_group_ami_type
      platform       = var.management_node_group_platform
      instance_types = var.management_node_group_instance_types
      capacity_type  = var.management_node_group_capacity_type
      min_size       = var.management_node_group_min_size
      max_size       = var.management_node_group_max_size
      desired_size   = var.management_node_group_desired_size
      disk_size      = var.management_node_group_disk_size
      labels = {
        "nodegroup"               = var.management_node_group_name
        "node.kubernetes.io/role" = var.management_node_group_role
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

# resource "aws_kms_key" "cluster_encyption_key" {
#   description             = "Encryption key for kubernetes-secrets envelope encryption"
#   enable_key_rotation     = true
#   deletion_window_in_days = 7

#   tags = {
#     Name = "${var.instance_name}-kms"
#   }
# }

# resource "aws_kms_alias" "this" {
#   name          = "alias/${var.instance_name}-kms"
#   target_key_id = aws_kms_key.cluster_encyption_key.key_id
# }

module "vpc_cni_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.1.0"

  role_name             = "${var.instance_name}-vpc-cni"
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
  version = "~> 5.1.0"

  role_name             = "${var.instance_name}-ebs-csi-controller-sa"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

data "aws_vpc" "vpc" {
  tags = {
    Name = "${var.instance_name}-vpc"
  }
}

data "aws_subnets" "cluster_private_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  tags = {
    Tier = var.subnet_identifier
  }
}
