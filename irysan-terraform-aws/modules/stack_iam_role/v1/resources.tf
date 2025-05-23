data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "deploy_role" {
  name = "deploy-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          "AWS" = "arn:aws:iam::${var.aws_account_shared_services_id}:user/gitlab-pipeline"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "ecs_deploy_policy" {
  name        = "ecs-deploy-policy"
  description = "Deploy ecs policy for the IAM role"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "iam:ListRoles",
          "iam:ListGroups",
          "iam:ListAttachedRolePolicies",
          "iam:GetRole",
          "iam:GetPolicyVersion",
          "iam:GetPolicy",
          "ecs:UpdateService",
          "ecs:RunTask",
          "ecs:RegisterTaskDefinition",
          "ecs:List*",
          "ecs:Describe*",
          "iam:PassRole",
          "application-autoscaling:PutScalingPolicy",
          "application-autoscaling:Describe*",
          "application-autoscaling:DeleteScalingPolicy"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

# Grant access to ECR repos on Shared Services account.
resource "aws_iam_policy" "ecr_shared_services_policy" {
  name        = "ecr-shared-services-policy"
  description = "ECR Shared Services policy for the IAM role"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ecr:DescribeImageScanFindings",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeImageReplicationStatus",
          "ecr:DescribeRepositories",
          "ecr:ListTagsForResource",
          "ecr:BatchGetRepositoryScanningConfiguration",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetRepositoryPolicy",
          "ecr:GetLifecyclePolicy",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:ecr:*:231044375577:repository/*"
      },
      {
        Action = [
          "ecr:GetRegistryPolicy",
          "ecr:DescribeRegistry",
          "ecr:GetAuthorizationToken",
          "ecr:GetRegistryScanningConfiguration"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

# Grant access to Docker Host Deployment Actions from Runner on own Region and Account.
resource "aws_iam_policy" "docker_host_deploy_policy" {
  name        = "docker-host-deploy-policy"
  description = "Docker Host Deployment policy for the IAM role"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ec2messages:GetMessages",
          "ssmmessages:CreateControlChannel",
          "ssm:DescribeInstanceInformation",
          "ssm:ListCommands",
          "ssm:ListCommandInvocations",
          "ssm:ListAssociations",
          "ssm:ListInstanceAssociations",
          "ssm:StartSession",
          "ssm:UpdateInstanceInformation",
          "ssm:SendCommand",
          "ssm:GetCommandInvocation",
          "ssm:TerminateSession"
        ],
        Effect   = "Allow",
        Resource = [
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*",
          "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*",
          "arn:aws:ssm:${data.aws_region.current.name}::document/AWS-RunShellScript"
        ]
      },
      {
        Action = [
          "ec2:DescribeInstances"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:*"
      },
      {
        Action = [
          "secretsmanager:ListSecrets"
        ],
        Effect   = "Allow",
        Resource = "*"
      }      
    ]
  })
}

# Attach ECS policy.
resource "aws_iam_role_policy_attachment" "ecs_attachment" {
  role       = aws_iam_role.deploy_role.name
  policy_arn = aws_iam_policy.ecs_deploy_policy.arn
}

# Attach ECR policy.
resource "aws_iam_role_policy_attachment" "ecr_attachment" {
  role       = aws_iam_role.deploy_role.name
  policy_arn = aws_iam_policy.ecr_shared_services_policy.arn
}

# Attach Docker Host policy.
resource "aws_iam_role_policy_attachment" "docker_host_attachment" {
  role       = aws_iam_role.deploy_role.name
  policy_arn = aws_iam_policy.docker_host_deploy_policy.arn
}
