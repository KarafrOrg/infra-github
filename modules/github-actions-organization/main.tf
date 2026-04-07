resource "github_actions_organization_variable" "variables" {
  for_each                = var.variables
  value                   = each.value.value
  variable_name           = each.key
  visibility              = each.value.visibility
  selected_repository_ids = try(each.value.selected_repository_ids, null)
}
