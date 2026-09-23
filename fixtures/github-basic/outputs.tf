output "full_name" {
  description = "The owner/name slug of the repository."
  value       = github_repository.this.full_name
}

output "resource_id" {
  description = "The node id of the repository."
  value       = github_repository.this.node_id
}
