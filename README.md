# Terraform module that creates S3 buckets secured by Bitbucket OIDC roles

Generates S3 buckets, IAM roles and policies.
These policies control access to the buckets and restrict their use to Bitbucket repositories within a Bitbucket
workspace.
Access is granted via OIDC roles set from within in a Bitbucket pipeline.
Policies are also added that prevent public or non-secure access to the bucket.

## License

This module is licensed under the [MIT License](./LICENSE).

## Usage

The module is hosted on GitHub and can be used by referencing a tag or branch.

The example below allows the `my-project` repository in the `my-bitbucket-account` workspace to use the `my-repository.example.com` bucket as a maven repository.
It allows reading from the whole bucket and writing to the folders
  - `snapshots/com/example/my-project`
  - `releases/com/example/my-project`

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
      repo_name   = "my-project"
      repo_uuid   = "12345678-abcd-1234-abcd-123456789012"
      bucket_name = "my-repository.example.com"
      folders     = [""]
      actions     = [
        "s3:ListBucket",
        "s3:GetObject",
      ]
    },
    {
      repo_name   = "my-project"
      repo_uuid   = "12345678-abcd-1234-abcd-123456789012"
      bucket_name = "my-repository.example.com"
      folders     = [
        "snapshots/com/example/my-project",
        "releases/com/example/my-project"
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

| Variables                | Required | Type                                                                                                                                     | Default  | Description                                                                                                                            |
|--------------------------|:--------:|:-----------------------------------------------------------------------------------------------------------------------------------------|----------|----------------------------------------------------------------------------------------------------------------------------------------|
| bitbucket_workspace_name |    ✔     | string                                                                                                                                   |          | The name of the Bitbucket workspace                                                                                                    |
| bitbucket_workspace_uuid |    ✔     | string                                                                                                                                   |          | The UUID of the Bitbucket workspace                                                                                                    |
| bitbucket_workspace_oidc |    ✔     | object({<br/>add_resource:bool<br/>thumbprint:string<br/>})                                                                              |          | The OIDC configuration for the Bitbucket workspace. If a resource is not added, the existing resource will be used                     |
| role_name_prefix         |    ✔     | string                                                                                                                                   |          | The prefix to use for the IAM roles. If a `role_strategy` of `ONE` is used, it will be used as the role name                           |
| permissions              |    ✔     | list(object({<br/>role_name:string<br/>repo_uuid:string<br/>bucket_name:string<br/>folders:list(string)<br/>actions:list(string)<br/>})) |          | List of permissions to apply. Entries in the `folders` list allow actions on the folder (or bucket if empty) and everything inside it. |
| role_strategy            |          | string                                                                                                                                   | ONE      | Which roles to add, one of [ONE, PER_BUCKET, PER_REPOSITORY]. Policies will be added to the roles accordingly                          |
| bucket_versioning        |          | string                                                                                                                                   | Disabled | S3 bucket versioning option, one of [Enabled, Suspended, Disabled]                                                                     |

| Outputs    | Type         | Description                                  |
|------------|:-------------|----------------------------------------------|
| role_names | list(string) | List of IAM role names created by the module |


## Use in Bitbucket Pipelines

The module outputs a list of IAM role names.
These can be used in a Bitbucket pipeline as follows:
(this example uses the `PER_REPOSITORY` role strategy)

```yaml
image: amazon/aws-cli:2.x.x # TODO use a valid up-to-date image version

definitions:
  scripts:
    - script: &install-jq yum install -y jq
    - script: &assume-role |
        export AWS_ROLE="MyRolePrefix_${BITBUCKET_WORKSPACE}_${BITBUCKET_REPO_SLUG}"
        export AWS_ACCOUNT_ID=123456789012
        export AWS_SESSION_CREDENTIALS=$(aws sts assume-role-with-web-identity \
          --role-arn           "arn:aws:iam::${AWS_ACCOUNT_ID}:role/${AWS_ROLE}" \
          --role-session-name  "${BITBUCKET_WORKSPACE}-${BITBUCKET_REPO_SLUG}-session-${BITBUCKET_BUILD_NUMBER}" \
          --web-identity-token "${BITBUCKET_STEP_OIDC_TOKEN}" \
          --duration-seconds   3600)
        export AWS_ACCESS_KEY_ID=$(    echo "$AWS_SESSION_CREDENTIALS" | jq -r '.Credentials.AccessKeyId')
        export AWS_SECRET_ACCESS_KEY=$(echo "$AWS_SESSION_CREDENTIALS" | jq -r '.Credentials.SecretAccessKey')
        export AWS_SESSION_TOKEN=$(    echo "$AWS_SESSION_CREDENTIALS" | jq -r '.Credentials.SessionToken')

pipelines:
  default:
    - step:
        oidc: true # Required for OIDC authentication
        name: Test
        script:
          - *install-jq
          - *assume-role
          - echo "TODO: Test the project, read/write to bucket, etc."
```

## AWS limits and role strategy

AWS enforces limits on the number of policies per role (20) and the size of a policy (6,144 characters).
This can sometimes prevent a single role from being created with all the necessary permissions.
Therefore, the `role_strategy` variable can be used to work around these limits by creating multiple roles.

The example above uses a `role_strategy` set to `PER_REPOSITORY` which means that a role will be created for each repository.
It can also be set to `PER_BUCKET` which will create a role for each bucket or `ONE` which will create a single role containing all policies.
