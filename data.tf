
data "aws_vpc" "vpc" {
  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

data "aws_subnets" "cluster_private_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  tags = {
    Tier = var.node_subnet_identifier
  }
}

data "aws_subnets" "cluster_intra_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  tags = {
    Tier = var.intra_subnet_identifier
  }
}