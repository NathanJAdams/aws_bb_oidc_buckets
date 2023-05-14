data "aws_iam_policy_document" "assume_role" {
  statement {
    sid    = "AssumeRole"
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
#    condition {
#      test     = "StringEquals"
#      variable = "${local.bitbucket_oidc_url}:aud"
#      values   = [local.bitbucket_audience]
#    }
    condition {
      test     = "StringLike"
      variable = "${local.bitbucket_oidc_url}:sub"
      values   = distinct(sort([for permission in var.permissions : "{${trim(permission.repo_uuid, "{}")}}:*"]))
    }
  }
}

data "aws_iam_policy_document" "secure_transport" {
  for_each = aws_s3_bucket.bucket

  statement {
    sid    = "SecureTransport"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = [
      each.value.arn,
      "${each.value.arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

data "aws_iam_policy_document" "role_access" {
  for_each = local.role_permissions

  dynamic "statement" {
    for_each = each.value

    content {
      sid       = statement.value.sid
      actions   = statement.value.actions
      resources = statement.value.resources

      condition {
        test     = "StringLike"
        variable = "${local.bitbucket_oidc_url}:sub"
        values   = [statement.value.sub]
      }
    }
  }
}
