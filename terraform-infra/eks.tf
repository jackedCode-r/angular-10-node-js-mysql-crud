module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.30"

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids
  cluster_additional_security_group_ids = [data.aws_security_group.existing_sg.id]

  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.small"]
      min_size       = 1
      max_size       = 4
      desired_size   = 2

      vpc_security_group_ids = [data.aws_security_group.existing_sg.id]
    }
  }
}