locals {
  bitbucket_audience      = "ari:cloud:bitbucket::workspace/${trim(var.bitbucket_workspace_uuid, "{}")}"
  bitbucket_oidc_bare_url = "api.bitbucket.org/2.0/workspaces/${var.bitbucket_workspace_name}/pipelines-config/identity/oidc"
  bitbucket_oidc_url      = "https://${local.bitbucket_oidc_bare_url}"
  bucket_names            = toset(var.permissions[*].bucket_name)
  cleaned_permissions     = [
    for permission in var.permissions : {
      repo_name   = permission.repo_name
      repo_uuid   = permission.repo_uuid
      bucket_name = permission.bucket_name
      bucket_keys = distinct(flatten([
        for folder in permission.folders : [
          (trim(folder, "/*") == "" ? "" : "/${trim(folder, "/*")}"), # bucket/folder
          (trim(folder, "/*") == "" ? "/*" : "/${trim(folder, "/*")}/*"), # files
        ]
      ]))
      actions = permission.actions
    }
  ]
  all_permissions = [
    for index, permission in local.cleaned_permissions : {
      group_key_bucket = replace("${var.role_name_prefix}_${permission.bucket_name}", "/[^a-zA-Z0-9_+=,.@-]/", "")
      group_key_repo   = replace("${var.role_name_prefix}_${var.bitbucket_workspace_name}_${permission.repo_name}", "/[^a-zA-Z0-9_+=,.@-]/", "")
      group_key_single = replace(var.role_name_prefix, "/[^a-zA-Z0-9_+=,.@-]/", "")
      sid              = "S3Access${index}"
      actions          = permission.actions
      resources        = [
        for bucket_key in permission.bucket_keys :
        "arn:aws:s3:::${permission.bucket_name}${bucket_key}"
      ]
      sub = "{${trim(permission.repo_uuid, "{}")}}:*"
    }
  ]
  permission_group_key = var.role_strategy == "PER_BUCKET" ? "group_key_bucket" : var.role_strategy == "PER_REPOSITORY" ? "group_key_repo" : "group_key_single"
  role_permissions     = {
    for permission in local.all_permissions :
    permission[local.permission_group_key] => permission...
  }
  role_names = distinct([
    for permission in local.all_permissions :
    permission[local.permission_group_key]
  ])
}
