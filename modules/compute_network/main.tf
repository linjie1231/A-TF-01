# ==========================================
# 1. 网络拓扑结构 (Network Topology)
# ==========================================
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "${var.environment}-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false # 不自动分配公网 IP

  tags = { Name = "${var.environment}-subnet" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.environment}-igw" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = { Name = "${var.environment}-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# ==========================================
# 2. 安全组设置 (Security Group)
# ==========================================
resource "aws_security_group" "ec2_sg" {
  name        = "${var.environment}-ec2-sg"
  description = "Security group with custom SSH port open to world"
  vpc_id      = aws_vpc.main.id

  # 满足需求：将22端口改为6022，并对全部网络(0.0.0.0/0)开放
  ingress {
    from_port   = 60022
    to_port     = 60022
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Custom SSH port open to world"
  }

  # 默认出站规则
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.environment}-sg" }
}

# ==========================================
# 3. IAM 资源配置 (IAM Resources)
# ==========================================
# 创建 IAM 角色，允许 EC2 服务信任并使用它
resource "aws_iam_role" "ec2_role" {
  name = "${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "://amazonaws.com"
        }
      }
    ]
  })
}

# 创建一个基础的只读策略（示例：允许读取 S3）
resource "aws_iam_policy" "s3_read_only" {
  name        = "${var.environment}-s3-readonly-policy"
  description = "Provides read-only access to S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:*"]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# 将策略附加到角色
resource "aws_iam_role_policy_attachment" "role_policy_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_read_only.arn
}

# 创建实例配置文件 (Instance Profile) - 这是将 IAM 角色绑定到 EC2 的桥梁
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# ==========================================
# 4. EC2 实例创建 (Compute Resource)
# ==========================================
resource "aws_instance" "web_server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id
  
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = var.key_name

  # 不分配公网 IP
  associate_public_ip_address = false

  # 挂载刚刚创建的 IAM 实例配置文件
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  # 根磁盘（默认加密）
  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  # 数据盘：不加密
  ebs_block_device {
    device_name           = "/dev/sdb"
    volume_size           = 50
    volume_type           = "gp3"
    encrypted             = false # 不加密
    delete_on_termination = true
  }

  tags = {
    Name        = "${var.environment}-web-instance"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
