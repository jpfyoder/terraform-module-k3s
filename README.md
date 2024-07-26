# terraform-module-k3s
![terraform test](https://github.com/jpfyoder/terraform-module-k3s/actions/workflows/terraform_test.yaml/badge.svg)
![tofu test](https://github.com/jpfyoder/terraform-module-k3s/actions/workflows/tofu_test.yaml/badge.svg)

Automate provisioning and maintenance of [k3s](https://k3s.io/) clusters via terraform.

## Usage
> [!WARNING]
> Certain secrets may be persisted in terraform state as a necessity of how this module manages deployments. State encryption is highly recommended if you use this module, as these secrets will be stored in **plaintext** and thus guarding of the state files is of utmost importance.

For a very simple, single server
```terraform
module "k3s" {
  source = "git::github.com/jpfyoder/terraform-module-k3s.git"

  nodes = {
    "node-0" = {
        role = "bootstrap"
        host = "server.example.com"
        user = "root"
    }
  }

  # flannel_backend = "wireguard-native"
  ssh_private_key = var.ssh_private_key
}
```

To connect to the cluster, you must retrieve the Kubeconfig via connecting to a server node and grabbing the `/etc/rancher/k3s/k3s.yaml` file. You can use this [as is mentioned in the k3s docs](https://docs.k3s.io/cluster-access).

## Things that are Not Implemented

- [ ]

# Terraform Docs

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [null_resource.k3s_bootstrap_server](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.k3s_key_distribution](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.k3s_label](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.k3s_node](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.k3s_taint](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_k3s_args"></a> [additional\_k3s\_args](#input\_additional\_k3s\_args) | Additional arguments to pass to the k3s installer. | `list(string)` | `[]` | no |
| <a name="input_datastore_endpoint"></a> [datastore\_endpoint](#input\_datastore\_endpoint) | Specify external datastore endpoint. Postgres (postgres://), MySQL/MariaDB (mysql://), or etcd (https://). | `string` | `null` | no |
| <a name="input_enable_embedded_etcd"></a> [enable\_embedded\_etcd](#input\_enable\_embedded\_etcd) | Enable embedded etcd. Requires an odd number of servers greater than 1. Disables SQLite. Cannot be used with datastore\_endpoint. | `bool` | `false` | no |
| <a name="input_fixed_registration_host"></a> [fixed\_registration\_host](#input\_fixed\_registration\_host) | External load balancer hostname or address for communication with k3s servers in an HA configuration. | `string` | `null` | no |
| <a name="input_flannel_backend"></a> [flannel\_backend](#input\_flannel\_backend) | Flannel backend to use. Can be 'none', 'vxlan', 'host-gw', or 'wireguard-native'. Defaults to 'vxlan'. | `string` | `null` | no |
| <a name="input_k3s_version"></a> [k3s\_version](#input\_k3s\_version) | Version of k3s to install. Should be a version tag as found on the k3s GitHub repository (https://github.com/k3s-io/k3s/releases). | `string` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Default labels to apply to all nodes. | `list(string)` | `[]` | no |
| <a name="input_nodes"></a> [nodes](#input\_nodes) | Map of k3s nodes to create. | <pre>map(object({<br>    # Required<br>    role = string<br>    host = string<br>    user = string<br>    # Optional<br>    internal_address     = optional(string, null)<br>    k3s_version          = optional(string, null)<br>    labels               = optional(list(string), [])<br>    taints               = optional(list(string), [])<br>    uninstall_on_destroy = optional(bool, null)<br>    additional_k3s_args  = optional(list(string), [])<br>  }))</pre> | `{}` | no |
| <a name="input_ssh_private_key"></a> [ssh\_private\_key](#input\_ssh\_private\_key) | SSH private key to use for connecting to nodes. | `string` | `null` | no |
| <a name="input_taints"></a> [taints](#input\_taints) | Default taints to apply to all nodes. | `list(string)` | `[]` | no |
| <a name="input_uninstall_on_destroy"></a> [uninstall\_on\_destroy](#input\_uninstall\_on\_destroy) | Uninstall k3s on nodes when the Terraform resources are destroyed. | `bool` | `true` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
