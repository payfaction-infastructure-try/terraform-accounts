output "load_balancer_ip" {
  value = data.terraform_remote_state.main_infrastructure.outputs.load_balancer_ip
}