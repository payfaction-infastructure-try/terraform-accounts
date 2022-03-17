provider "aws" {
  access_key = "${var.AWS_ACCESS_KEY_ID}"
  secret_key = "${var.AWS_SECRET_ACCESS_KEY}"
  region     = "${var.AWS_REGION}"
}

provider "circleci" {
  api_token    = "${var.CIRCLECI_API_TOKEN}"
  organization = "${var.CIRCLECI_ORGANIZATION}"
  vcs_type     = "${var.CIRCLECI_VCS_TYPE}"
}

data "terraform_remote_state" "main_infrastructure" {
  backend = "remote"
  config = {
    organization = "${var.REMOTE_ORGANIZATION}"
    workspaces = {
      name = "${var.REMOTE_WORKSPACE}"
    }
  }
}

resource "aws_security_group" "accounts_sg" {
  name        = "${local.aws_ecs_service_security_group_name}"
  vpc_id      = data.terraform_remote_state.main_infrastructure.outputs.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [data.terraform_remote_state.main_infrastructure.outputs.load_balancer_security_group_id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "accounts_tg" {
  name        = "${local.aws_alb_target_group_name}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.main_infrastructure.outputs.vpc_id
  target_type = "ip"
}

resource "aws_lb_listener_rule" "accounts_listener_rule" {
  listener_arn = data.terraform_remote_state.main_infrastructure.outputs.lb_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.accounts_tg.arn
  }
    condition {
      path_pattern {
        values = ["/accounts"]
      }
    }
}

module "app_infrastructure" {
  source  = "payfaction-infastructure-try/infrastructure/application"
  version = "0.0.8"

  aws_resource_name_prefix = var.AWS_RESOURCE_NAME_PREFIX
  cluster_id = data.terraform_remote_state.main_infrastructure.outputs.cluster_id
  private_subnets = data.terraform_remote_state.main_infrastructure.outputs.private_subnets
  target_group_id = aws_lb_target_group.accounts_tg.id
  lb_listener = data.terraform_remote_state.main_infrastructure.outputs.lb_listener
  security_group_id = aws_security_group.accounts_sg.id
}

resource "circleci_context" "accounts-app-context" {
  name  = "${var.AWS_RESOURCE_NAME_PREFIX}"
}

resource "circleci_context_environment_variable" "accounts-app-context-env" {
  for_each = {
    AWS_RESOURCE_NAME_PREFIX = "${var.AWS_RESOURCE_NAME_PREFIX}"
    AWS_ECR_REPOSITORY_URL = "${module.app_infrastructure.aws_ecr_repository.registry_id}.dkr.ecr.${var.AWS_REGION}.amazonaws.com"
    AWS_ECR_REPOSITORY_REGISTRY_ID = "${module.app_infrastructure.aws_ecr_repository.registry_id}"
  }

  variable   = each.key
  value      = each.value
  context_id = circleci_context.accounts-app-context.id
}
