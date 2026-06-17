variable "aws_region" {
  type        = string
  description = "Target AWS Region"
}

variable "environment" {
  type        = string
  description = "Environment tag name"
}

variable "instance_type" {
  type        = string
  description = "EC2 Instance Size"
}

variable "ami_id" {
  type        = string
  description = "The AMI ID to use for the instance"
}

variable "key_name" {
  type        = string
  description = "The name of the pre-existing AWS SSH Key Pair"
}

variable "ebs_optimized" {
  description = "If true, the launched EC2 instance will be EBS-optimized"
  type        = bool
  default     = true
}

variable "monitoring" {
  description = "If true, the launched EC2 instance will have detailed monitoring enabled"
  type        = bool
  default     = false
}