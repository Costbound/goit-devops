variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnets" {
  description = "List of CIDR blocks for the public subnets"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of CIDR blocks for the private subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones for the subnets"
  type        = list(string)
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name for subnet tags"
  type        = string
  default     = ""
}

