provider "aws" {
  region = var.region
}

data "aws_vpc" "launch_vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnet_ids" "vpc_subnets" {
  vpc_id = data.aws_vpc.launch_vpc.id
  filter {
    name   = "tag:Name"
    values = ["*public*"]
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/userdata.sh.tpl")
  vars = {
    github_token  = var.github_token
    github_owner  = var.github_owner
  }
}

resource "aws_security_group" "gh_runner_sg" {
  name        = "github_actions_runner_sg"
  description = "Allow outbound internet connections"
  vpc_id      = data.aws_vpc.launch_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "github-runner-sg"
  }
}

data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

module "autoscale_group" {
  source = "git::https://github.com/cloudposse/terraform-aws-ec2-autoscale-group.git?ref=0.4.0"

  namespace = "shared"
  stage     = "prod"
  name      = "github-actions-runners"
  image_id                    = data.aws_ami.amazon-linux-2.id
  instance_type               = var.instance_type
  security_group_ids          = [aws_security_group.gh_runner_sg.id]
  subnet_ids                  = data.aws_subnet_ids.vpc_subnets.ids
  health_check_type           = "EC2"
  min_size                    = 2
  max_size                    = 35
  wait_for_capacity_timeout   = "5m"
  associate_public_ip_address = true
  user_data_base64            = "${base64encode(data.template_file.user_data.rendered)}"

  tags = {
    Environment = "production"
    PXT = "Shared"
  }

  # Auto-scaling policies and CloudWatch metric alarms
  autoscaling_policies_enabled           = "true"
  cpu_utilization_high_threshold_percent = "75"
  cpu_utilization_low_threshold_percent  = "20"
}
