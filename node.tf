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
