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
}

data "template_file" "user_data" {
  template = file("${path.module}/userdata.sh.tpl")
  vars = {
    github_token  = var.github_token
    github_repo   = var.github_repo
    github_owner  = var.github_owner
  }
}

resource "aws_security_group" "gh_runner_sg" {
  name        = "gh_runner_sg"
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
    Name = "github-runner-${var.github_repo}-sg"
  }
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 3.0"
  
  name = "github-runner-${var.github_repo}-asg"

  # Launch configuration
  lc_name = "github-runner-${var.github_repo}-lc"

  image_id        = "ami-0e8c04af2729ff1bb"
  instance_type   = var.instance_type
  security_groups = [aws_security_group.gh_runner_sg.id]

  root_block_device = [
    {
      volume_size = "20"
      volume_type = "gp2"
    },
  ]

  # Auto scaling group
  asg_name                  = "github-runner-${var.github_repo}-asg"
  vpc_zone_identifier       = data.aws_subnet_ids.vpc_subnets.ids
  health_check_type         = "EC2"
  min_size                  = 1
  max_size                  = 20
  desired_capacity          = 1
  wait_for_capacity_timeout = 0

  user_data                 = data.template_file.user_data.rendered
  key_name                  = "github-action-runners"

  tags = [
    {
      key                 = "team"
      value               = var.team
      propagate_at_launch = true
    },
    {
      key                 = "Name"
      value               = "github-runner-${var.github_repo}"
      propagate_at_launch = true
    },
  ]

  tags_as_map = {
    type = "github_runner"
  }
}
