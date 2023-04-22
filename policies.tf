resource "aws_iam_policy" "role_access" {
  for_each = local.role_permissions

  name   = each.key
  policy = data.aws_iam_policy_document.role_access[each.key].json
}

resource "aws_iam_role_policy_attachment" "role_access" {
  for_each = local.role_permissions

  role       = aws_iam_role.role[each.key].name
  policy_arn = aws_iam_policy.role_access[each.key].arn
}
