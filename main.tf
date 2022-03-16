provider "aws" {
  access_key = "${var.AWS_ACCESS_KEY_ID}"
  secret_key = "${var.AWS_SECRET_ACCESS_KEY}"
  region     = "${var.AWS_REGION}"
}

provider "circleci" {
  api_token    = "${var.CIRCLECI_API_TOKEN}"
  vcs_type     = "${var.CIRCLECI_VCS_TYPE}"
  organization = "${var.CIRCLECI_ORGANIZATION}"
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

module "main-infrastructure" {
  source  = "payfaction-infastructure-try/infrastructure/application"
  version = "0.0.3"

  aws_resource_name_prefix = var.AWS_RESOURCE_NAME_PREFIX
  vpc_id = data.terraform_remote_state.main_infrastructure.outputs.vpc_id
  load_balancer_id =  data.terraform_remote_state.main_infrastructure.outputs.load_balancer_id
  load_balancer_security_group_id = data.terraform_remote_state.main_infrastructure.outputs.load_balancer_security_group_id
  cluster_id = data.terraform_remote_state.main_infrastructure.outputs.cluster_id
  private_subnets = data.terraform_remote_state.main_infrastructure.outputs.private_subnets
}

resource "circleci_context" "aws" {
  name  = "${var.AWS_RESOURCE_NAME_PREFIX}"
}

resource "circleci_context_environment_variable" "aws_env" {
  for_each = {
    AWS_RESOURCE_NAME_PREFIX = "${var.AWS_RESOURCE_NAME_PREFIX}"
  }

  variable   = each.key
  value      = each.value
  context_id = circleci_context.aws.id
}
