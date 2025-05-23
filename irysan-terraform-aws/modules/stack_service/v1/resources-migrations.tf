resource "aws_ecs_task_definition" "migrations" {
  count = var.create_migrations_task_definition ? 1 : 0

  family = "${var.service_name}-migrations"

  requires_compatibilities = ["FARGATE"]

  cpu          = "1024"
  memory       = "2048"
  network_mode = "awsvpc"

  task_role_arn      = module.ecs.services[var.service_name].tasks_iam_role_arn
  execution_role_arn = module.ecs.services[var.service_name].task_exec_iam_role_arn

  container_definitions = jsonencode([var.migrations_task_definition])
}

resource "aws_cloudwatch_log_group" "migrations" {
  count = var.create_migrations_task_definition ? 1 : 0

  name = "/aws/ecs/${var.service_name}/migrations"
}
