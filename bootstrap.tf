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
