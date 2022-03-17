
locals {
  aws_ecs_service_security_group_name = "${var.AWS_RESOURCE_NAME_PREFIX}-ecs-service-security-group"

  aws_alb_target_group_name = "${var.AWS_RESOURCE_NAME_PREFIX}-alb-target-group"
}