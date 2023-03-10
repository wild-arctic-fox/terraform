# EKS cluster module - create control plane("master nodes")

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.10.0"

  # must match to "kubernetes.io/cluster/test-app-eks-cluster" = "shared"
  cluster_name = "test-app-eks-cluster"
  #   k8s version
  cluster_version = "1.24"
  subnet_ids      = module.test-app-vpc.private_subnets
  vpc_id          = module.test-app-vpc.vpc_id

  tags = {
    Environment = "dev"
  }

  eks_managed_node_groups = {
    dev = {
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      instance_types = ["t2.small"]
    }
  }
}
