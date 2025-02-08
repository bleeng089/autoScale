provider "aws" {
  region = "us-east-1"
}

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




