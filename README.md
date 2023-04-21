# Terraform module for S3 buckets secured by Bitbucket OIDC roles

Generates S3 buckets, IAM roles and policies.
These policies control access to the buckets and restrict their use to Bitbucket repositories within a Bitbucket workspace.
Access is granted via OIDC roles set from within in a Bitbucket pipeline.

## License

This module is licensed under the [MIT License](./LICENSE).

## Usage

The module is hosted on GitHub and can be used by referencing a tag or branch as follows:

```hcl
module "oidc_buckets" {
  source = "github.com/NathanJAdams/aws_bb_oidc_buckets.git?ref=1.0"

  bitbucket_workspace_name = "MyBitbucketWorkspace"
  bitbucket_workspace_uuid = "12345678-abcd-1234-abcd-123456789012"
  bitbucket_workspace_oidc = {
    add_resource = true
    thumbprint   = "1234567890123456789012345678901234567890"
  }
  bucket_versioning = "Enabled"
  role_name_prefix  = "MyRolePrefix"
  role_strategy     = "PER_REPOSITORY"
  permissions       = [
    {
      repo_name   = "MyRepo"
      repo_uuid   = "12345678-abcd-1234-abcd-123456789012"
      bucket_name = "MyBucket"
      bucket_keys = [
        "*",
      ]
      actions = [
        "s3:ListBucket",
        "s3:GetObject",
      ]
    },
    {
      repo_name   = "MyRepo"
      repo_uuid   = "12345678-abcd-1234-abcd-123456789012"
      bucket_name = "MyBucket"
      bucket_keys = [
        "snapshots",
        "releases"
      ]
      actions = [
        "s3:PutObject",
        "s3:DeleteObject",
      ]
    }
  ]
}
```

## Variables

| Variables                | Required | Type                                                                                                                                         | Default  | Description                                                                                                        |
|--------------------------|:--------:|:---------------------------------------------------------------------------------------------------------------------------------------------|----------|--------------------------------------------------------------------------------------------------------------------|
| bitbucket_workspace_name |    ✔     | string                                                                                                                                       |          | The name of the Bitbucket workspace                                                                                |
| bitbucket_workspace_uuid |    ✔     | string                                                                                                                                       |          | The UUID of the Bitbucket workspace                                                                                |
| bitbucket_workspace_oidc |    ✔     | object({<br/>add_resource:bool<br/>thumbprint:string<br/>})                                                                                  |          | The OIDC configuration for the Bitbucket workspace. If a resource is not added, the existing resource will be used |
| role_name_prefix         |    ✔     | string                                                                                                                                       |          | The prefix to use for the IAM roles. If a `role_strategy` of `ONE` is used, it will be used as the role name       |
| permissions              |    ✔     | list(object({<br/>role_name:string<br/>repo_uuid:string<br/>bucket_name:string<br/>bucket_keys:list(string)<br/>actions:list(string)<br/>})) |          | List of permissions to apply                                                                                       |
| role_strategy            |          | string                                                                                                                                       | ONE      | Which roles to add, one of [ONE, PER_BUCKET, PER_REPOSITORY]. Policies will be added to the roles accordingly      |
| bucket_versioning        |          | string                                                                                                                                       | Disabled | S3 bucket versioning option, one of [Enabled, Suspended, Disabled]                                                 |

| Outputs    | Type         | Description                                  |
|------------|:-------------|----------------------------------------------|
| role_names | list(string) | List of IAM role names created by the module |
