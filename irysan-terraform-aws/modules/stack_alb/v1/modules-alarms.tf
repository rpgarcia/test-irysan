data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "alerts_sns_topic" {
  source  = "terraform-aws-modules/sns/aws"
  version = "5.4.0"

  create = var.create_alarms

  name = "${var.name}-opsgenie"

  topic_policy_statements = {
    pub = {
      actions = ["sns:Publish"]
      principals = [{
        type        = "Service"
        identifiers = ["cloudwatch.amazonaws.com"]
      }]
      conditions = [
        {
          test     = "ArnLike"
          variable = "aws:SourceArn"
          values   = ["arn:aws:cloudwatch:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:alarm:*"]
        },
        {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = [data.aws_caller_identity.current.account_id]
        },
      ]
    }
  }

  subscriptions = {
    opsgenie = {
      protocol = "https"
      endpoint = "${var.opsgenie_endpoint}${var.opsgenie_key}"
    }
  }
}

# ALB target response time bigger than 2 second for more than 5min.
module "alb_response_time_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "~> 3.0"

  create_metric_alarm = var.create_alarms

  alarm_name          = "${var.name}-alarm-alb-response-time"
  alarm_description   = "ALB target response time >= 2 seconds"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 2 # in seconds
  period              = 5 * 60

  dimensions = {
    LoadBalancer = module.alb.id
  }

  namespace   = "AWS/ApplicationELB"
  metric_name = "TargetResponseTime"
  statistic   = "Average"

  alarm_actions = [module.alerts_sns_topic.topic_arn]
}

# ALB HTTPCode_ELB_5XX_COUNT bigger than 5.
module "alb_http_5xx_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "~> 3.0"

  create_metric_alarm = var.create_alarms

  alarm_name          = "${var.name}-alarm-alb-http-5xx"
  alarm_description   = "ALB HTTPCode_ELB_5XX_COUNT > 5"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 5
  period              = 5 * 60

  dimensions = {
    LoadBalancer = module.alb.id
  }

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_ELB_5XX_Count"
  statistic   = "Sum"

  alarm_actions = [module.alerts_sns_topic.topic_arn]
}
