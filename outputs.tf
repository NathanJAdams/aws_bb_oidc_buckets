output "role_names" {
  value = distinct(sort([for policy in local.cleaned_permissions : policy[local.permission_group_key]]))
}
