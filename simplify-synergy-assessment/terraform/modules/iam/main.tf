resource "aws_iam_user" "this" {
  name                 = var.name
  path                 = var.path
  force_destroy        = var.force_destroy
  permissions_boundary = var.permissions_boundary

  tags = var.tags
}

resource "aws_iam_user_login_profile" "this" {
  count = var.create_user && var.create_iam_user_login_profile ? 1 : 0


  user                    = aws_iam_user.this.name
  pgp_key                 = var.pgp_key
  password_length         = var.password_length
  password_reset_required = var.password_reset_required

  #   lifecycle {
  #     ignore_changes = [password_reset_required]
  #   }
}

resource "aws_iam_access_key" "this" {
  count = var.create_user && var.create_iam_access_key && var.pgp_key != "" ? 1 : 0

  user    = aws_iam_user.this.name
  pgp_key = var.pgp_key
  status  = var.iam_access_key_status
}

resource "aws_iam_access_key" "this_no_pgp" {
  count = var.create_user && var.create_iam_access_key && var.pgp_key == "" ? 1 : 0

  user   = aws_iam_user.this.name
  status = var.iam_access_key_status
}

resource "aws_iam_user_policy_attachment" "this" {
  for_each = { for k, v in var.policy_arns : k => v if var.create_user }

  user       = aws_iam_user.this.name
  policy_arn = each.value
}