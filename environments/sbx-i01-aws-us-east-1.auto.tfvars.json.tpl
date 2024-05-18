{
  "cluster_name": "sbx-i01-aws-us-east-1",
  "aws_account_id": "{{ op://empc-lab/aws-dps-2/aws-account-id }}",
  "aws_assume_role": "PSKRoles/PSKPlatformEKSBaseRole",
  "aws_region": "us-east-1",

  "eks_version": "1.29",
  "enable_log_types": ["api", "audit", "authenticator", "controllerManager", "scheduler"],
  "node_subnet_identifier": "node",
  "intra_subnet_identifier": "intra",

  "management_node_group_name": "management-arm-rkt-mng",
  "management_node_group_role": "management",
  "management_node_group_ami_type": "BOTTLEROCKET_ARM_64",
  "management_node_group_disk_size": "50",
  "management_node_group_capacity_type": "SPOT",
  "management_node_group_desired_size": "3",
  "management_node_group_max_size": "5",
  "management_node_group_min_size": "3",
  "management_node_group_instance_types": ["t4g.2xlarge","m6g.2xlarge","m7g.2xlarge"]
}