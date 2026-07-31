variable "region" {
  default = "ap-south-1"
}

variable "cluster_name" {
  default = "mean-app-cluster"
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}