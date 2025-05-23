resource "aws_iam_role" "terraform_deploy_role" {
  name = "terraform_deploy_role"

  assume_role_policy = <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
JSON

  tags = local.tags
}

data "aws_iam_policy" "full_admin" {
  name = "AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "terraform_cloud_policy_attachment" {
  role       = aws_iam_role.terraform_deploy_role.name
  policy_arn = data.aws_iam_policy.full_admin.arn
}
