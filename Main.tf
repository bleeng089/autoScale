provider "aws" {
  region = "us-east-1"
}

# Create an IAM role for EC2 Instance Connect
resource "aws_iam_role" "ec2_instance_connect_role" {
  name = "ec2_instance_connect_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach the EC2 Instance Connect policy to the IAM role
resource "aws_iam_role_policy_attachment" "ec2_instance_connect_policy_attachment" {
  role       = aws_iam_role.ec2_instance_connect_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Define a VPC
resource "aws_vpc" "example_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "example_vpc"
  }
}

# Define a subnet
resource "aws_subnet" "example_subnet" {
  vpc_id            = aws_vpc.example_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "example_subnet"
  }
}

# Define a security group
resource "aws_security_group" "example_sg" {
  vpc_id      = aws_vpc.example_vpc.id
  name        = "example_sg"
  description = "Allow internal SSH"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Allow SSH only from internal IPs within the VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["192.168.1.0/24"]  # Specific egress CIDR block
  }

  tags = {
    Name = "example_sg"
  }
}

# Define an EC2 instance
resource "aws_instance" "example" {
  ami                         = "ami-085ad6ae776d8f09c"  # Use a valid AMI ID for your region
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.example_subnet.id
  security_groups             = [aws_security_group.example_sg.name]
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_connect_profile.name
  associate_public_ip_address = false  # Do not associate a public IP

  tags = {
    Name = "ExampleInstance"
  }

  # Enable instance metadata service v2
  metadata_options {
    http_tokens = "required"
  }

  # Enable root volume encryption
  root_block_device {
    volume_type           = "gp2"
    volume_size           = 8
    delete_on_termination = true
    encrypted             = true
  }

  # Enable termination protection
  disable_api_termination = true
}

# Create an IAM instance profile for EC2 Instance Connect
resource "aws_iam_instance_profile" "ec2_instance_connect_profile" {
  name = "ec2_instance_connect_profile"
  role = aws_iam_role.ec2_instance_connect_role.name
}

output "instance_id" {
  value = aws_instance.example.id
}

output "instance_public_ip" {
  value = aws_instance.example.public_ip
}
