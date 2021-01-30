terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
  }
}

provider "aws" {
  profile = "coalfire-interview"
  region  = "us-east-1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.68.0"
  name = "coalfire-interview"
  cidr = "10.0.0.0/16"
  azs = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnets = ["10.0.2.0/24", "10.0.3.0/24"]
}

module "ec2-instance-private" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.16.0"
  name = "coalfire-interview-private"
  ami = "ami-098bb5d92c8886ca1"
  instance_type = "t2.micro"
  key_name = "coalfire-interview"
  root_block_device = [{volume_size = 20}]
  subnet_id = module.vpc.private_subnets[0]
}

module "ec2-instance-public" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.16.0"
  name = "coalfire-interview-public"
  ami = "ami-098bb5d92c8886ca1"
  instance_type = "t2.micro"
  key_name = "coalfire-interview"
  root_block_device = [{volume_size = 20}]
  subnet_id = module.vpc.public_subnets[0]
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"
  name = "coalfire-interview"
  load_balancer_type = "application"
  vpc_id = module.vpc.vpc_id
  subnets = module.vpc.private_subnets
  security_groups = ["sg-05706c9fcd332463c"]
  target_groups = [
    {
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
    }
  ]
  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]
}

resource "aws_alb_target_group_attachment" "target" {
  target_group_arn = module.alb.target_group_arns[0]
  port             = 80
  target_id        = module.ec2-instance-private.id[0]
}