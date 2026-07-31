output "cluster_name" {
  value = module.eks.cluster_name
}

output "rds_endpoint" {
  value = aws_db_instance.mean_app_db.address
}

output "vpc_id" {
  value = data.aws_vpc.default.id
}