resource "github_team" "team" {
  name        = var.name
  description = var.description
  privacy     = var.privacy

  parent_team_id = var.parent_team_id

  ldap_dn = var.ldap_dn
}

resource "github_team_membership" "membership" {
  for_each = var.members

  team_id  = github_team.team.id
  username = each.key
  role     = each.value
}

removed {
  from = github_team.team["platform"]
  lifecycle {
    destroy = true
  }
}

removed {
  from = github_team.team["infrastructure"]
  lifecycle {
    destroy = true
  }
}

removed {
  from = github_team.team["backend-api"]
  lifecycle {
    destroy = true
  }
}

