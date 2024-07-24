# Single k3s Embedded SQLite Server with Two Agents
run "embedded_sqlite_two_agents" {
  command = plan

  variables {
    nodes = {
      a = {
        role                 = "bootstrap"
        user                 = "root"
        host                 = "example.com"
      },
      b = {
        role                 = "agent"
        user                 = "root"
        host                 = "example.com"
      },
      c = {
        role                 = "agent"
        user                 = "root"
        host                 = "example.com"
      },
    }
  }
}

# Three k3s Servers with Embedded etcd with Two Agents (HA) and Fixed Registration Host (External Load Balancer)
run "embedded_etcd_external_lb" {
  command = plan

}

# Two k3s Servers with External Postgres Datastore with Two Agents (HA) and Wireguard-Native Flannel Backend
run "external_postgres_wireguard_flannel" {
  command = plan

}

# Three k3s Servers, Two Nodes with Label and Taint Creation
#   Global, Server-specific, and Agent-specific Labels and Taints
run "labels_taints" {
  command = plan

}

# Three k3s Servers with Different k3s Versions, two specified specifically on the node(s)
#   Tests upgradability of k3s
run "different_k3s_versions" {
  command = plan

}

# Additional k3s Arguments
run "additional_k3s_args" {
  command = plan

}
