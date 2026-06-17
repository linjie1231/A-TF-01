variable "environment" { type = string }
variable "instance_type" { type = string }
variable "ami_id" { type = string }
variable "key_name" { type = string }
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