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
      "sudo scp -i k3s.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null /var/lib/rancher/k3s/server/token ${self.triggers.node_user}@${self.triggers.node_host}:~/token",
      "ssh -i k3s.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${self.triggers.node_user}@${self.triggers.node_host} 'sudo mkdir -p /var/lib/rancher/k3s/server && sudo mv ~/token /var/lib/rancher/k3s/server/token'",
      "rm -f ~/token",
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

# Retrieve kubeconfig from the bootstrap server
data "remote_file" "kubeconfig" {
  conn {
    host        = local.bootstrap_server.host
    user        = local.bootstrap_server.user
    private_key = var.ssh_private_key
    sudo        = true
  }

  path = "/etc/rancher/k3s/k3s.yaml"

  depends_on = [null_resource.k3s_bootstrap_server]
}
