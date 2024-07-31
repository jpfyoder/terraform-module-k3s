terraform {
  required_version = ">= 1.0"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
    remote = {
      source  = "tenstad/remote"
      version = ">= 0.1.3"
    }
  }
}

locals {
  nodes = {
    for name, node in var.nodes : name => {
      # Meta
      name           = name
      bootstrap_host = coalesce(local.bootstrap_server.internal_address, local.bootstrap_server.host)
      # Required
      role = node.role
      host = node.host
      user = node.user
      # Global
      fixed_registration_host = var.fixed_registration_host
      datastore_endpoint      = var.datastore_endpoint
      enable_embedded_etcd    = var.enable_embedded_etcd
      flannel_backend         = var.flannel_backend
      # Optional
      internal_address     = node.internal_address
      k3s_version          = try(coalesce(node.k3s_version, var.k3s_version), null)
      labels               = concat(var.labels, node.labels)
      taints               = concat(var.taints, node.taints)
      uninstall_on_destroy = coalesce(node.uninstall_on_destroy, var.uninstall_on_destroy)
      additional_k3s_args  = concat(node.additional_k3s_args, var.additional_k3s_args)
    }
  }

  install_command = length(local.nodes) > 0 ? {
    for name, node in local.nodes : name => join(" ", compact([
      for x in split("\n",
        templatefile("${path.module}/scripts/install.tftpl.sh", node)
      ) : trimspace(split("#", x)[0])
    ]))
  } : {}

  bootstrap_server = length(var.nodes) > 0 ? [
    for node in var.nodes : node if node.role == "bootstrap"
  ][0] : null

  kubernetes_api_server_url = "https://${coalesce(var.fixed_registration_host, local.bootstrap_server.host)}:6443"

  kubeconfig             = replace(data.remote_file.kubeconfig.content, "https://127.0.0.1:6443", local.kubernetes_api_server_url)
  client_certificate     = try(yamldecode(local.kubeconfig).users[0].user.client-certificate-data, null)
  client_key             = try(yamldecode(local.kubeconfig).users[0].user.client-key-data, null)
  cluster_ca_certificate = try(yamldecode(local.kubeconfig).clusters[0].cluster.certificate-authority-data, null)
}
