provider "aws" {
  region = var.aws_region
}

# 调用局部模块并传递变量
module "ec2_infrastructure" {
  source        = "./modules/compute_network"
  environment   = var.environment
  instance_type = var.instance_type
  ami_id        = var.ami_id
  key_name      = var.key_name
}

output "instance_private_ip" {
  value       = module.ec2_infrastructure.private_ip
  description = "The private IP allocated to the EC2 instance"
}
