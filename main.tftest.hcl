# Single k3s Embedded SQLite Server with Two Agents
run "embedded_sqlite_two_agents" {
  command = plan

  variables {
    nodes = {
      a = {
        role                 = "bootstrap"
        user                 = "root"
        host                 = "a.example.com"
      },
      b = {
        role                 = "agent"
        user                 = "root"
        host                 = "b.example.com"
      },
      c = {
        role                 = "agent"
        user                 = "root"
        host                 = "c.example.com"
      },
    }
  }

  assert {
    condition = null_resource.k3s_bootstrap_server["a"].triggers.install_command == "curl -sfL https://get.k3s.io | K3S_NODE_NAME='a' sh -s - server"
    error_message   = "Server a is misconfigured"
  }

  assert {
    condition = null_resource.k3s_node["b"].triggers.install_command == "curl -sfL https://get.k3s.io | K3S_NODE_NAME='b' sh -s - agent --server \"https://a.example.com:6443\" --token-file /var/lib/rancher/k3s/server/token"
    error_message   = "Agent server b is misconfigured"
  }

  assert {
    condition = null_resource.k3s_node["c"].triggers.install_command == "curl -sfL https://get.k3s.io | K3S_NODE_NAME='c' sh -s - agent --server \"https://a.example.com:6443\" --token-file /var/lib/rancher/k3s/server/token"
    error_message   = "Agent server c is misconfigured"
  }
}

# Three k3s Servers with Embedded etcd with Two Agents (HA) and Fixed Registration Host (External Load Balancer)
run "embedded_etcd_external_lb" {
  command = plan

  variables {
    nodes = {
      a = {
        role                 = "bootstrap"
        user                 = "root"
        host                 = "a.example.com"
      },
      b = {
        role                 = "server"
        user                 = "root"
        host                 = "b.example.com"
      },
      c = {
        role                 = "server"
        user                 = "root"
        host                 = "c.example.com"
      },
      d = {
        role                 = "agent"
        user                 = "root"
        host                 = "d.example.com"
      },
      e = {
        role                 = "agent"
        user                 = "root"
        host                 = "e.example.com"
      },
    }

    enable_embedded_etcd = true
    fixed_registration_host = "lb.example.com"
  }

  assert {
    condition = null_resource.k3s_bootstrap_server["a"].triggers.install_command == "curl -sfL https://get.k3s.io | K3S_NODE_NAME='a' sh -s - server --tls-san \"lb.example.com\" --cluster-init"
    error_message   = "Server a is misconfigured"
  }

  assert {
    condition = null_resource.k3s_node["b"].triggers.install_command == "curl -sfL https://get.k3s.io | K3S_NODE_NAME='b' sh -s - server --tls-san \"lb.example.com\" --token-file /var/lib/rancher/k3s/server/token --server \"https://a.example.com:6443\""
    error_message   = "Server b is misconfigured"
  }

  assert {
    condition = null_resource.k3s_node["c"].triggers.install_command == "curl -sfL https://get.k3s.io | K3S_NODE_NAME='c' sh -s - server --tls-san \"lb.example.com\" --token-file /var/lib/rancher/k3s/server/token --server \"https://a.example.com:6443\""
    error_message   = "Server c is misconfigured"
  }

  assert {
    condition = null_resource.k3s_node["d"].triggers.install_command == "curl -sfL https://get.k3s.io | K3S_NODE_NAME='d' sh -s - agent --server \"https://lb.example.com:6443\" --token-file /var/lib/rancher/k3s/server/token"
    error_message   = "Agent server d is misconfigured"
  }

  assert {
    condition = null_resource.k3s_node["e"].triggers.install_command == "curl -sfL https://get.k3s.io | K3S_NODE_NAME='e' sh -s - agent --server \"https://lb.example.com:6443\" --token-file /var/lib/rancher/k3s/server/token"
    error_message   = "Agent server e is misconfigured"
  }
}

# Two k3s Servers with External Postgres Datastore with Two Agents (HA) and Wireguard-Native Flannel Backend
run "external_postgres_wireguard_flannel" {
  command = plan

  variables {
    nodes = {
      a = {
        role                 = "bootstrap"
        user                 = "root"
        host                 = "a.example.com"
      },
      b = {
        role                 = "server"
        user                 = "root"
        host                 = "b.example.com"
      },
      c = {
        role                 = "agent"
        user                 = "root"
        host                 = "c.example.com"
      },
      d = {
        role                 = "agent"
        user                 = "root"
        host                 = "d.example.com"
      },
    }

    datastore_endpoint = "postgres://postgres:postgres@pg.example.com:5432/postgres"
    flannel_backend = "wireguard-native"
  }

  assert {
    condition = null_resource.k3s_bootstrap_server["a"].triggers.install_command == "curl -sfL https://get.k3s.io | K3S_NODE_NAME='a' sh -s - server --flannel-backend \"wireguard-native\" --node-external-ip \"a.example.com\" --flannel-external-ip --datastore-endpoint \"postgres://postgres:postgres@pg.example.com:5432/postgres\""
    error_message   = "Server a is misconfigured"
  }

  assert {
    condition = null_resource.k3s_node["b"].triggers.install_command == "curl -sfL https://get.k3s.io | K3S_NODE_NAME='b' sh -s - server --flannel-backend \"wireguard-native\" --node-external-ip \"b.example.com\" --flannel-external-ip --datastore-endpoint \"postgres://postgres:postgres@pg.example.com:5432/postgres\" --token-file /var/lib/rancher/k3s/server/token"
    error_message   = "Server b is misconfigured"
  }

  assert {
    condition = null_resource.k3s_node["c"].triggers.install_command == "curl -sfL https://get.k3s.io | K3S_NODE_NAME='c' sh -s - agent --server \"https://a.example.com:6443\" --node-external-ip \"c.example.com\" --token-file /var/lib/rancher/k3s/server/token"
    error_message   = "Server c is misconfigured"
  }

  assert {
    condition = null_resource.k3s_node["d"].triggers.install_command == "curl -sfL https://get.k3s.io | K3S_NODE_NAME='d' sh -s - agent --server \"https://a.example.com:6443\" --node-external-ip \"d.example.com\" --token-file /var/lib/rancher/k3s/server/token"
    error_message   = "Server d is misconfigured"
  }
}

# Test global, Server-specific, and Agent-specific Labels and Taints
run "labels_taints" {
  command = plan

  variables {
    nodes = {
      a = {
        role                 = "bootstrap"
        user                 = "root"
        host                 = "a.example.com"
        labels               = ["foo=bar", "baz=qux"]
        taints               = ["foo=bar:NoSchedule", "baz=qux:NoExecute"]
      },
      b = {
        role                 = "server"
        user                 = "root"
        host                 = "b.example.com"
        labels               = ["a=b", "c=d"]
      },
      c = {
        role                 = "server"
        user                 = "root"
        host                 = "c.example.com"
        taints               = ["a=b:NoSchedule", "c=d:NoExecute"]
      },
      d = {
        role                 = "agent"
        user                 = "root"
        host                 = "d.example.com"
      }
    }

    enable_embedded_etcd = true
    labels = ["global=foo", "bar=baz"]
    taints = ["global=foo:NoSchedule", "bar=baz:NoExecute"]
  }

  assert {
    condition = null_resource.k3s_label["a_bar=baz"].triggers.label == "bar=baz" && null_resource.k3s_label["a_baz=qux"].triggers.label == "baz=qux" && null_resource.k3s_label["a_foo=bar"].triggers.label == "foo=bar" && null_resource.k3s_label["a_global=foo"].triggers.label == "global=foo"
    error_message   = "Node a labels are misconfigured"
  }

  assert {
    condition = null_resource.k3s_label["b_a=b"].triggers.label == "a=b" && null_resource.k3s_label["b_c=d"].triggers.label == "c=d" && null_resource.k3s_label["b_global=foo"].triggers.label == "global=foo" && null_resource.k3s_label["b_bar=baz"].triggers.label == "bar=baz"
    error_message   = "Node b labels are misconfigured"
  }

  assert {
    condition = null_resource.k3s_label["c_global=foo"].triggers.label == "global=foo" && null_resource.k3s_label["c_bar=baz"].triggers.label == "bar=baz"
    error_message   = "Node c labels are misconfigured"
  }

  assert {
    condition = null_resource.k3s_label["d_global=foo"].triggers.label == "global=foo" && null_resource.k3s_label["d_bar=baz"].triggers.label == "bar=baz"
    error_message   = "Node d labels are misconfigured"
  }

  assert {
    condition = null_resource.k3s_taint["a_foo=bar:NoSchedule"].triggers.taint == "foo=bar:NoSchedule" &&  null_resource.k3s_taint["a_baz=qux:NoExecute"].triggers.taint == "baz=qux:NoExecute" && null_resource.k3s_taint["a_global=foo:NoSchedule"].triggers.taint == "global=foo:NoSchedule" && null_resource.k3s_taint["a_bar=baz:NoExecute"].triggers.taint == "bar=baz:NoExecute"
    error_message   = "Node a taints are misconfigured"
  }

  assert {
    condition = null_resource.k3s_taint["b_global=foo:NoSchedule"].triggers.taint == "global=foo:NoSchedule" && null_resource.k3s_taint["b_bar=baz:NoExecute"].triggers.taint == "bar=baz:NoExecute"
    error_message   = "Node b taints are misconfigured"
  }

  assert {
    condition = null_resource.k3s_taint["c_a=b:NoSchedule"].triggers.taint == "a=b:NoSchedule" && null_resource.k3s_taint["c_c=d:NoExecute"].triggers.taint == "c=d:NoExecute" && null_resource.k3s_taint["c_global=foo:NoSchedule"].triggers.taint == "global=foo:NoSchedule" && null_resource.k3s_taint["c_bar=baz:NoExecute"].triggers.taint == "bar=baz:NoExecute"
    error_message   = "Node c taints are misconfigured"
  }

  assert {
    condition = null_resource.k3s_taint["d_global=foo:NoSchedule"].triggers.taint == "global=foo:NoSchedule" && null_resource.k3s_taint["d_bar=baz:NoExecute"].triggers.taint == "bar=baz:NoExecute"
    error_message   = "Node d taints are misconfigured"
  }
}

# Three k3s Servers with Different k3s Versions, two specified specifically on the node(s)
#   Tests upgradability of k3s
run "different_k3s_versions" {
  command = plan

  variables {
    nodes = {
      a = {
        role                 = "bootstrap"
        user                 = "root"
        host                 = "a.example.com"
        k3s_version          = "v1.30.3-rc1+k3s1"
      },
      b = {
        role                 = "server"
        user                 = "root"
        host                 = "b.example.com"
        k3s_version          = "v1.30.2+k3s2"
      },
      c = {
        role                 = "server"
        user                 = "root"
        host                 = "c.example.com"
      },
      d = {
        role                 = "agent"
        user                 = "root"
        host                 = "d.example.com"
        k3s_version          = "v1.30.2-rc1+k3s2"
      }
    }

    enable_embedded_etcd = true
    k3s_version = "v1.28.11+k3s2"
  }

  assert {
    condition = null_resource.k3s_bootstrap_server["a"].triggers.install_command == "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='v1.30.3-rc1+k3s1' K3S_NODE_NAME='a' sh -s - server --cluster-init"
    error_message   = "Server a is misconfigured"
  }

  assert {
    condition = null_resource.k3s_node["b"].triggers.install_command == "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='v1.30.2+k3s2' K3S_NODE_NAME='b' sh -s - server --token-file /var/lib/rancher/k3s/server/token --server \"https://a.example.com:6443\""
    error_message   = "Server b is misconfigured"
  }

  assert {
    condition = null_resource.k3s_node["c"].triggers.install_command == "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='v1.28.11+k3s2' K3S_NODE_NAME='c' sh -s - server --token-file /var/lib/rancher/k3s/server/token --server \"https://a.example.com:6443\""
    error_message   = "Server c is misconfigured"
  }

  assert {
    condition = null_resource.k3s_node["d"].triggers.install_command == "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='v1.30.2-rc1+k3s2' K3S_NODE_NAME='d' sh -s - agent --server \"https://a.example.com:6443\" --token-file /var/lib/rancher/k3s/server/token"
    error_message   = "Agent server d is misconfigured"
  }
}

# Additional k3s Arguments
run "additional_k3s_args" {
  command = plan

  variables {
    nodes = {
      a = {
        role                 = "bootstrap"
        user                 = "root"
        host                 = "a.example.com"
        additional_k3s_args  = ["--no-deploy", "traefik"]
      },
      b = {
        role                 = "server"
        user                 = "root"
        host                 = "b.example.com"
        additional_k3s_args  = ["--no-deploy", "local-storage"]
      },
      c = {
        role                 = "server"
        user                 = "root"
        host                 = "c.example.com"
      },
      d = {
        role                 = "agent"
        user                 = "root"
        host                 = "d.example.com"
        additional_k3s_args  = ["--no-deploy traefik", "--no-deploy", "metrics-server"]
      }
    }

    enable_embedded_etcd = true
    additional_k3s_args = ["--no-deploy", "servicelb"]
  }

  assert {
    condition = null_resource.k3s_bootstrap_server["a"].triggers.install_command == "curl -sfL https://get.k3s.io | K3S_NODE_NAME='a' sh -s - server --cluster-init --no-deploy traefik --no-deploy servicelb"
    error_message   = "Server a is misconfigured"
  }

  assert {
    condition = null_resource.k3s_node["b"].triggers.install_command == "curl -sfL https://get.k3s.io | K3S_NODE_NAME='b' sh -s - server --token-file /var/lib/rancher/k3s/server/token --server \"https://a.example.com:6443\" --no-deploy local-storage --no-deploy servicelb"
    error_message   = "Server b is misconfigured"
  }

  assert {
    condition = null_resource.k3s_node["c"].triggers.install_command == "curl -sfL https://get.k3s.io | K3S_NODE_NAME='c' sh -s - server --token-file /var/lib/rancher/k3s/server/token --server \"https://a.example.com:6443\" --no-deploy servicelb"
    error_message   = "Server c is misconfigured"
  }

  assert {
    condition = null_resource.k3s_node["d"].triggers.install_command == "curl -sfL https://get.k3s.io | K3S_NODE_NAME='d' sh -s - agent --server \"https://a.example.com:6443\" --token-file /var/lib/rancher/k3s/server/token --no-deploy traefik --no-deploy metrics-server --no-deploy servicelb"
    error_message   = "Agent server d is misconfigured"
  }
}
