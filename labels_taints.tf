# Apply labels to k3s nodes
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
      "sudo /usr/local/bin/k3s kubectl label nodes ${self.triggers.name} ${self.triggers.label} --overwrite",
    ]
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "#!/bin/bash",
      "sudo /usr/local/bin/k3s kubectl label nodes ${self.triggers.name} ${split("=", self.triggers.label)[0]}-",
    ]
  }

  depends_on = [null_resource.k3s_bootstrap_server]
}

# Apply taints to k3s nodes
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
      "sudo /usr/local/bin/k3s kubectl taint nodes ${self.triggers.name} ${self.triggers.taint} --overwrite",
    ]
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "sudo /usr/local/bin/k3s kubectl taint nodes ${self.triggers.name} ${split("=", self.triggers.taint)[0]}-",
    ]
  }

  depends_on = [null_resource.k3s_bootstrap_server]
}
