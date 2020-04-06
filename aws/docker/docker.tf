provider "aws" {
  region = var.region
}

data "aws_vpc" "vpc" {
  tags = {
    Type        = "platform-vpc"
  }
}

data "aws_subnet" "subnet_docker" {
  vpc_id        = data.aws_vpc.vpc.id

  tags = {
    Type        = "private"
    Docker 	    = "1"
  }
}

data "aws_iam_instance_profile" "ec2_ssm_profile" {
  name          = "platform-ec2-ssm-profile"
}

data "aws_security_group" "bastion_sg" {
  tags = {
    Name 	      = "platform-bastion"
  }
}
 
resource "aws_security_group" "docker_sg" {
 
  vpc_id        = data.aws_vpc.vpc.id
  name          = "platform-docker"
  description   = "SSH from bastion server"
 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
 
    security_groups = [data.aws_security_group.bastion_sg.id]
  }
 
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
 
    security_groups = [data.aws_security_group.bastion_sg.id]
  }

  ingress {
    from_port   = 9990
    to_port     = 9990
    protocol    = "tcp"

    security_groups = [data.aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name 	= "platform-docker"
    Environment = var.env
  }
}
 
resource "aws_instance" "docker" {
  ami 		              = "ami-0e38b48473ea57778"
  instance_type         = "t2.micro"
  key_name 	            = var.key_pair_name
  subnet_id 	          = data.aws_subnet.subnet_docker.id
  security_groups       = [aws_security_group.docker_sg.id]
  private_ip	          = var.private_ip 
  iam_instance_profile  = data.aws_iam_instance_profile.ec2_ssm_profile.name
 
  tags = {
    Name 	              = "platform-docker"
    HostType 	          = "docker"
    Environment         = var.env
    "Patch Group"     	= var.env
  }
}
