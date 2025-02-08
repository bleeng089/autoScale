provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "example" {
  ami           = "ami-085ad6ae776d8f09c"  # Use a valid AMI ID for your region
  instance_type = "t3.nano"

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
}

resource "aws_security_group" "example" {
  name        = "example_sg"
  description = "Example security group"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH from anywhere (for demonstration purposes; restrict in production)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ExampleSecurityGroup"
  }
}
