data "aws_iam_openid_connect_provider" "oidc" {
  count = var.bitbucket_workspace_oidc.add_resource ? 0 : 1

  url   = local.bitbucket_oidc_url
}

resource "aws_iam_openid_connect_provider" "oidc" {
  count           = var.bitbucket_workspace_oidc.add_resource ? 1 : 0

  url             = local.bitbucket_oidc_url
  client_id_list  = [local.bitbucket_audience]
  thumbprint_list = [var.bitbucket_workspace_oidc.thumbprint]
}

locals {
  oidc_provider_arn = var.bitbucket_workspace_oidc.add_resource ? aws_iam_openid_connect_provider.oidc[0].arn : data.aws_iam_openid_connect_provider.oidc[0].arn
}
