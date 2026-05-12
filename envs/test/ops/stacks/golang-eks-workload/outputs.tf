output "release_name" {
  description = "Helm release name"
  value       = helm_release.golang_app.name
}

output "release_namespace" {
  description = "Helm release namespace"
  value       = helm_release.golang_app.namespace
}

output "release_status" {
  description = "Helm release status"
  value       = helm_release.golang_app.status
}

output "release_version" {
  description = "Helm chart version deployed"
  value       = helm_release.golang_app.version
}
