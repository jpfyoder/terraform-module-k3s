curl -sfL https://get.k3s.io |
  # Set K3S_VERSION if specified
  %{if k3s_version != null}
  INSTALL_K3S_VERSION='${k3s_version}'
  %{endif}

  # Default to all installations
  K3S_NODE_NAME='${name}'
sh -s -
  # Run for all 'server-type' nodes
  %{if role == "server" || role == "bootstrap"}
  server
  # Set up fixed registration host (load balancer)
  %{if fixed_registration_host != null}
  --tls-san "${fixed_registration_host}"
  %{endif}

  # Set up datastore endpoint (external databases)
  %{if datastore_endpoint != null}
  --datastore-endpoint "${datastore_endpoint}"
  %{endif}
  # Otherwise, we are an agent
  %{else}
  agent
  # Fixed registration host on agent side
  %{if fixed_registration_host != null}
  --server "https://${fixed_registration_host}:6443"
  # Otherwise, just use the bootstrap host's IP or local IP to register
  %{else}
  --server "https://${bootstrap_host}:6443"
  %{endif}
  %{endif}

  # If node is not a bootstrap node, set the token file
  %{if role != "bootstrap"}
  --token-file /var/lib/rancher/k3s/server/token
  # Otherwise, node is a bootstrap node
  %{else}
  # If embedded etcd is enabled, add the --cluster-init flag to the bootstrap node
  %{if enable_embedded_etcd == true}
  --cluster-init
  %{endif}
  %{endif}

  # If the node is a server and embedded etcd is enabled, set the server flag
  %{if role == "server" && enable_embedded_etcd == true}
  --server "https://${bootstrap_host}:6443"
  %{endif}

  # Additional K3s arguments
  %{for a in additional_k3s_args}
  ${a}
  %{endfor}
