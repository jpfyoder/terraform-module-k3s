terraform {
  required_version = ">= 1.0"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
  }
}

locals {
  nodes = {
    for name, node in var.nodes : name => {
      # Meta
      name           = name
      bootstrap_host = local.bootstrap_server.host
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
}

# Represents the first server in the cluster
resource "null_resource" "k3s_bootstrap_server" {
  for_each = {
    for name, node in local.nodes : name => node if node.role == "bootstrap"
  }

  triggers = {
    user                 = each.value.user
    private_key          = var.ssh_private_key
    host                 = each.value.host
    uninstall_on_destroy = each.value.uninstall_on_destroy
    install_command      = local.install_command[each.key]
  }

  connection {
    type        = "ssh"
    user        = self.triggers.user
    private_key = self.triggers.private_key
    host        = self.triggers.host
  }

  provisioner "remote-exec" {
    when   = create
    inline = [self.triggers.install_command]
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = self.triggers.user
      private_key = self.triggers.private_key
      host        = self.triggers.host
    }

    when = destroy
    inline = self.triggers.uninstall_on_destroy == "true" ? [
      "/usr/local/bin/k3s-uninstall.sh"
    ] : ["echo 'Skipping uninstall'"]
  }
}

# Distribute the k3s key from the bootstrap server to all other servers
# NOTE: Assumes servers are in a trusted environment
resource "null_resource" "k3s_key_distribution" {
  for_each = {
    for name, node in local.nodes : name => node if node.role != "bootstrap"
  }

  triggers = {
    user        = local.bootstrap_server.user
    private_key = var.ssh_private_key
    host        = local.bootstrap_server.host

    node_user = each.value.user
    node_host = each.value.host
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = self.triggers.user
      private_key = self.triggers.private_key
      host        = self.triggers.host
    }

    when = create
    inline = [
      "#!/bin/bash",
      "sudo -i bash -c 'while : ; do [[ -f \"/var/lib/rancher/k3s/server/token\" ]] && break; echo \"Pausing until file exists.\"; sleep 1; done'",
      "echo \"${self.triggers.private_key}\" > k3s.pem",
      "chmod 400 k3s.pem",
      "scp -i k3s.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null /var/lib/rancher/k3s/server/token ${self.triggers.node_user}@${self.triggers.node_host}:~/token",
      "ssh -i k3s.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${self.triggers.node_user}@${self.triggers.node_host} 'sudo mkdir -p /var/lib/rancher/k3s/server && sudo mv ~/token /var/lib/rancher/k3s/server/token'",
      "rm -f k3s.pem",
    ]
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = self.triggers.node_user
      private_key = self.triggers.private_key
      host        = self.triggers.node_host
    }

    when = destroy
    inline = [
      "#!/bin/bash",
      "sudo rm -f /var/lib/rancher/k3s/server/token",
    ]
  }

  depends_on = [null_resource.k3s_bootstrap_server]
}

# Represents additional servers in the cluster
resource "null_resource" "k3s_node" {
  for_each = {
    for name, node in local.nodes : name => node if node.role != "bootstrap"
  }

  triggers = {
    user                 = each.value.user
    private_key          = var.ssh_private_key
    host                 = each.value.host
    uninstall_on_destroy = each.value.uninstall_on_destroy
    role                 = each.value.role
    install_command      = local.install_command[each.key]
  }

  connection {
    type        = "ssh"
    user        = self.triggers.user
    private_key = self.triggers.private_key
    host        = self.triggers.host
  }

  provisioner "remote-exec" {
    when   = create
    inline = [self.triggers.install_command]
  }

  #TODO: Use script
  provisioner "remote-exec" {
    when = destroy
    inline = self.triggers.uninstall_on_destroy == "true" ? [
      self.triggers.role == "server" ? "sudo /usr/local/bin/k3s-uninstall.sh" : "sudo /usr/local/bin/k3s-agent-uninstall.sh"
    ] : ["echo 'Skipping uninstall'"]
  }

  depends_on = [null_resource.k3s_key_distribution]
}

# Represents a label applied to a k3s node. Present in tf for convenience purposes.
resource "null_resource" "k3s_label" {
  for_each = merge([
    for name, node in local.nodes : {
      for label in node.labels : "${name}_${label}" => merge(node, { this_label = label })
    }
  ]...)

  triggers = {
    user        = local.bootstrap_server.user
    private_key = var.ssh_private_key
    host        = local.bootstrap_server.host
    name        = each.value.name
    label       = each.value.this_label
  }

  connection {
    type        = "ssh"
    user        = self.triggers.user
    private_key = self.triggers.private_key
    host        = self.triggers.host
  }

  provisioner "remote-exec" {
    when = create
    inline = [
      "#!/bin/bash",
      "sudo k3s kubectl label nodes ${self.triggers.name} ${self.triggers.label} --overwrite",
    ]
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "#!/bin/bash",
      "sudo k3s kubectl label nodes ${self.triggers.name} ${split("=", self.triggers.label)[0]}-",
    ]
  }

  depends_on = [null_resource.k3s_bootstrap_server]
}

# Represents a taint applied to a k3s node. Present in tf for convenience purposes.
resource "null_resource" "k3s_taint" {
  for_each = merge([
    for name, node in local.nodes : {
      for taint in node.taints : "${name}_${taint}" => merge(node, { this_taint = taint })
    }
  ]...)

  triggers = {
    user        = local.bootstrap_server.user
    private_key = var.ssh_private_key
    host        = local.bootstrap_server.host
    name        = each.value.name
    taint       = each.value.this_taint
  }

  connection {
    type        = "ssh"
    user        = self.triggers.user
    private_key = self.triggers.private_key
    host        = self.triggers.host
  }

  provisioner "remote-exec" {
    when = create
    inline = [
      "#!/bin/bash",
      "sudo k3s kubectl taint nodes ${self.triggers.name} ${self.triggers.taint} --overwrite",
    ]
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "sudo k3s kubectl taint nodes ${self.triggers.name} ${split("=", self.triggers.taint)[0]}-",
    ]
  }

  depends_on = [null_resource.k3s_bootstrap_server]
}
