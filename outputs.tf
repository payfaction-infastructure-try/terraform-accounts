output "load_balancer_ip" {
  value = data.terraform_remote_state.main_infrastructure.outputs.load_balancer_ip
}

output "aws_ecr_repository_url" {
  value = module.app_infrastructure.aws_ecr_repository.repository_url
}

output "aws_ecr_repository_registry_id" {
  value = module.app_infrastructure.aws_ecr_repository.registry_id
}