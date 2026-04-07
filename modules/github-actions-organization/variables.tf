variable "variables" {
  description = "A list of variables to create at the organization level. Each variable should be an object with the following attributes: variable_name, value, and visibility."
  type = map(object({
    value                   = string
    visibility              = string
    selected_repository_ids = optional(list(string))
  }))
}
