provider "aws" {
  region = "eu-central-1"
}

provider "kubernetes" {
  config_path = "~/.kube/config"
  host                   = data.aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority.0.data)
  token = data.aws_eks_cluster_auth.main.token
}

locals {
  region = "eu-central-1"
  name   = "eks-cluster-20240701-${random_string.suffix.result}"
  vpc_cidr = "172.0.0.0/16"
  azs      = ["eu-central-1a", "eu-central-1b"]
  public_subnets  = ["172.0.1.0/24", "172.0.2.0/24", "172.0.3.0/24"]
  private_subnets = ["172.0.101.0/24", "172.0.102.0/24", "172.0.103.0/24"]

  tags = {
    Example = local.name
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.11.1"

  cluster_name                   = local.name
  cluster_version                = "1.30"
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  enable_cluster_creator_admin_permissions = true

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["t3.medium"]
  }

  eks_managed_node_groups = {
    eks-node = {
      min_size     = 2
      max_size     = 4
      desired_size = 3

      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"
    }
  }

# Added to try to solve Istio issue

  node_security_group_additional_rules = {
  ingress_15017 = {
    description                   = "${local.name} Cluster API - Istio Webhook namespace.sidecar-injector.istio.io"
    protocol                      = "TCP"
    from_port                     = 15017
    to_port                       = 15017
    type                          = "ingress"
    source_cluster_security_group = true
  }
  ingress_15012 = {
    description                   = "${local.name} Cluster API to nodes ports/protocols"
    protocol                      = "TCP"
    from_port                     = 15012
    to_port                       = 15012
    type                          = "ingress"
    source_cluster_security_group = true
  }
  } 

  tags = local.tags
}

resource "null_resource" "kubeconfig_update" {
  provisioner "local-exec" {
    #interpreter = ["/bin/bash", "-c"]
    command     = "aws eks update-kubeconfig --region ${local.region} --name ${local.name}"
  }
  depends_on = [ module.eks.cluster ]
}

data "aws_eks_cluster" "main" {
  #depends_on = [ module.eks.cluster ]
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "main" {
  #depends_on = [ module.eks.cluster ]
  name = module.eks.cluster_name
}

resource "kubernetes_namespace" "test-app" {
  metadata {
    annotations = {
      name = "test-app"
    }

    labels = {
      mylabel = "test-app"
    }

    name = "test-app"
  }
}