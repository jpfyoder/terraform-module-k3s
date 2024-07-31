output "kubeconfig_yaml" {
  value       = local.kubeconfig
  sensitive   = true
  description = "Kubeconfig in YAML format"
}

output "client_certificate" {
  value       = local.client_certificate
  sensitive   = true
  description = "Client certificate for authenticating to the cluster"
}

output "client_key" {
  value       = local.client_key
  sensitive   = true
  description = "Client key for authenticating to the cluster"
}

output "cluster_ca_certificate" {
  value       = local.cluster_ca_certificate
  sensitive   = true
  description = "CA certificate for authenticating to the cluster"
}

output "kubernetes_api_server_url" {
  value       = local.kubernetes_api_server_url
  sensitive   = true
  description = "Kubernetes API server URL for the cluster, including the port"
}
