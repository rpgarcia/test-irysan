resource "aws_iam_user" "user" {
  name = var.username

  tags = var.tags
}

resource "aws_iam_user_policy_attachment" "attachment" {
  for_each   = toset(var.policies)
  user       = aws_iam_user.user.name
  policy_arn = each.value
}