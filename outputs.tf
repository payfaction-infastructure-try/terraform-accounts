output "load_balancer_ip" {
  value = data.terraform_remote_state.main_infrastructure.outputs.load_balancer_ip
}

output "aws_ecr_repository_url" {
  value = module.main-infrastructure.aws_ecr_repository_url
}