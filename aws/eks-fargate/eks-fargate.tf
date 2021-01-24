# TODO: tag nodes for patching, validate access to RDS

provider "aws" {
  region  = var.region
  profile = var.env
}

data "aws_vpc" "vpc" {
  tags = {
    Type = "platform-vpc"
  }
}

data "aws_subnet_ids" "subnet_ids" {
  vpc_id = data.aws_vpc.vpc.id
  tags = {
    Kubernetes = 1
    Type       = "private"
  }
}

data "aws_subnet" "subnet_id" {
  for_each = data.aws_subnet_ids.subnet_ids.ids
  id       = each.value
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.11"
}

module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name = var.eks_cluster_name
  cluster_version = var.eks_cluster_version
  subnets      = [for s in data.aws_subnet.subnet_id : s.id]

  tags = {
    Environment = var.env
  }

  vpc_id = data.aws_vpc.vpc.id

  fargate_profiles = {
    example = {
      namespace = "default"

      tags = {
        Environment = var.env
      }
    }
  }
}