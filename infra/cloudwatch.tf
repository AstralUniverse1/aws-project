resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/project1"
  retention_in_days = 7
}