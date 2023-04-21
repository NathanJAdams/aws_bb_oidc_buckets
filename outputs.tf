output "role_names" {
  value = distinct(sort([for policy in local.all_policies : policy[local.policy_group_key]]))
}
