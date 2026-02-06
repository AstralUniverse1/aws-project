data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  codecommit_repo_name = "project1"

  ecr_repos = [
    "project1-app",
    "project1-nginx",
  ]

  ecs_cluster_name = "project1-cluster"
  ecs_service_name = "project1-nginx"

  ecs_task_execution_role_arn = "arn:aws:iam::923337630273:role/project1-ecs-task-exec" # your existing role
}
