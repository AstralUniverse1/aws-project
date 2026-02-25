variable "enable_eventbridge_codecommit_trigger" {
  type    = bool
  default = false
}

resource "aws_cloudwatch_event_rule" "codecommit_main_push" {
  count       = var.enable_eventbridge_codecommit_trigger ? 1 : 0
  name        = "project1-codecommit-main-push"
  description = "Start project1-pipeline on CodeCommit push to main"

  event_pattern = jsonencode({
    source        = ["aws.codecommit"],
    "detail-type" = ["CodeCommit Repository State Change"],
    resources     = ["arn:aws:codecommit:${local.region}:${local.account_id}:${local.codecommit_repo_name}"],
    detail = {
      event         = ["referenceCreated", "referenceUpdated"],
      referenceType = ["branch"],
      referenceName = ["main"]
    }
  })
}

resource "aws_iam_role" "eventbridge_start_pipeline" {
  count = var.enable_eventbridge_codecommit_trigger ? 1 : 0
  name  = "project1-eventbridge-start-pipeline"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "events.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "eventbridge_start_pipeline" {
  count = var.enable_eventbridge_codecommit_trigger ? 1 : 0
  name  = "project1-eventbridge-start-pipeline"
  role  = aws_iam_role.eventbridge_start_pipeline[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["codepipeline:StartPipelineExecution"],
      Resource = aws_codepipeline.project1.arn
    }]
  })
}

resource "aws_cloudwatch_event_target" "start_pipeline" {
  count     = var.enable_eventbridge_codecommit_trigger ? 1 : 0
  rule      = aws_cloudwatch_event_rule.codecommit_main_push[0].name
  target_id = "project1-pipeline"
  arn       = aws_codepipeline.project1.arn
  role_arn  = aws_iam_role.eventbridge_start_pipeline[0].arn
}