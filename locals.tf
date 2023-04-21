locals {
  bitbucket_audience      = "ari:cloud:bitbucket::workspace/${trim(var.bitbucket_workspace_uuid, "{}")}"
  bitbucket_oidc_bare_url = "api.bitbucket.org/2.0/workspaces/${var.bitbucket_workspace_name}/pipelines-config/identity/oidc"
  bitbucket_oidc_url      = "https://${local.bitbucket_oidc_bare_url}"
  bucket_names            = toset(var.permissions[*].bucket_name)
  all_policies            = [
    for index, permission in var.permissions : {
      group_key_bucket = replace("${var.role_name_prefix}_${permission.bucket_name}", "/[^a-zA-Z0-9_+=,.@-]/", "")
      group_key_repo   = replace("${var.role_name_prefix}_${var.bitbucket_workspace_name}-${permission.repo_name}", "/[^a-zA-Z0-9_+=,.@-]/", "")
      group_key_single = replace(var.role_name_prefix, "/[^a-zA-Z0-9_+=,.@-]/", "")
      sid              = "S3Access${index}"
      actions          = permission.actions
      resources        = distinct(sort(flatten([
        for folder in permission.bucket_keys : flatten([
          (trim(folder, "/") == "" || trim(folder, "/") == "*") ? ["arn:aws:s3:::${permission.bucket_name}"] : [],
          "arn:aws:s3:::${permission.bucket_name}${(trim(folder, "/") == "" || trim(folder, "/") == "*") ? "/*" : format("/%s/*", folder)}"
        ])
      ])))
      sub = "{${trim(permission.repo_uuid, "{}")}}:*"
    }
  ]
  policy_group_key = var.role_strategy == "PER_BUCKET" ? "group_key_bucket" : var.role_strategy == "PER_REPOSITORY" ? "group_key_repo" : "group_key_single"
  role_policies    = {
    for policy in local.all_policies :
    policy[local.policy_group_key] => policy...
  }
}
