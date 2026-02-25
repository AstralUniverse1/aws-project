# ECS Fargate service running NGINX in a private subnet.
# Exposed later via an Application Load Balancer (HTTPS).

resource "aws_iam_role" "ecs_task_execution" {
  name = "project1-ecs-task-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_cluster" "main" {
  name = "project1-cluster"
}

resource "aws_security_group" "ecs_tasks" {
  name        = "project1-ecs-tasks"
  description = "ECS tasks (ingress added later from ALB SG)"
  vpc_id      = aws_vpc.main.id

  # no ingress yet (ALB will be added later)

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_task_definition" "nginx" {
  family                   = "project1-nginx"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = "923337630273.dkr.ecr.il-central-1.amazonaws.com/project1-nginx:latest"
      essential = true

      portMappings = [
        { containerPort = 80, hostPort = 80, protocol = "tcp" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = local.region
          awslogs-stream-prefix = "project1"
        }
      }

      dependsOn = [
        { containerName = "app", condition = "START" }
      ]
    },
    {
      name      = "app"
      image     = "923337630273.dkr.ecr.il-central-1.amazonaws.com/project1-app:latest"
      essential = true

      portMappings = [
        { containerPort = 5000, hostPort = 5000, protocol = "tcp" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = local.region
          awslogs-stream-prefix = "project1"
        }
      }

      environment = [
        { name = "MYSQL_HOST",     value = aws_db_instance.mysql.address },
        { name = "MYSQL_PORT",     value = "3306" },
        { name = "MYSQL_DATABASE", value = "appdb" },
        { name = "MYSQL_USER",     value = "appuser" }
      ]

      secrets = [
        { name = "MYSQL_PASSWORD", valueFrom = aws_secretsmanager_secret.db_password.arn }
      ]
    }
  ])
}

