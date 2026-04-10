output "team_id" {
  description = "The ID of the team"
  value       = github_team.team.id
}

output "team_node_id" {
  description = "The Node ID of the team"
  value       = github_team.team.node_id
}

output "team_slug" {
  description = "The slug of the team"
  value       = github_team.team.slug
}

output "team_name" {
  description = "The name of the team"
  value       = github_team.team.name
}

output "team_members_count" {
  description = "The number of members in the team"
  value       = github_team.team.members_count
}
