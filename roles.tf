resource "aws_iam_role" "role" {
  for_each = local.role_permissions

  name               = each.key
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}
