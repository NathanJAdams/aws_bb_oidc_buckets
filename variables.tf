variable "bitbucket_workspace_name" {
  type        = string
  description = "The name of the Bitbucket workspace"
}

variable "bitbucket_workspace_uuid" {
  type        = string
  description = "The UUID of the Bitbucket workspace"
}

variable "bitbucket_workspace_oidc" {
  type = object({
    add_resource = bool
    thumbprint   = string
  })
  description = "The OIDC configuration for the Bitbucket workspace and whether to add a resource for it. Not adding a resource will use the existing OIDC resource."
  default     = {
    add_resource = false
    thumbprint   = ""
  }
}

variable "permissions" {
  type = list(object({
    repo_name   = string
    repo_uuid   = string
    bucket_name = string
    folders     = list(string)
    actions     = list(string)
  }))
  description = "List of permissions to apply. Entries in the `folders` list allow actions on the folder (or bucket if empty) and everything inside it."
}

variable "bucket_versioning" {
  type        = string
  default     = "Disabled"
  description = "Versioning state of the bucket, one of [Enabled, Suspended, Disabled]"
  validation {
    condition     = contains(["Enabled", "Suspended", "Disabled"], var.bucket_versioning)
    error_message = "bucket_versioning must be one of [Enabled, Suspended, Disabled]"
  }
}

variable "role_name_prefix" {
  type        = string
  description = "The prefix to use for the role name"
}

variable "role_strategy" {
  type        = string
  default     = "ONE"
  description = "The role strategy to use, one of [ONE, PER_BUCKET, PER_REPOSITORY]"
  validation {
    condition     = contains(["ONE", "PER_BUCKET", "PER_REPOSITORY"], var.role_strategy)
    error_message = "role_strategy must be one of [ONE, PER_BUCKET, PER_REPOSITORY]"
  }
}
