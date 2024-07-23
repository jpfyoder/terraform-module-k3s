# Individual Resource Configuration Options
variable "nodes" {
  type = map(object({
    # Required
    role = string
    host = string
    user = string
    # Optional
    k3s_version          = optional(string, null)
    labels               = optional(list(string), [])
    taints               = optional(list(string), [])
    uninstall_on_destroy = optional(bool, null)
    additional_k3s_args  = optional(list(string), [])
  }))

  default     = {}
  description = "Map of k3s nodes to create."

  validation {
    condition     = alltrue([for name, node in var.nodes : node.role == "server" || node.role == "agent" || node.role == "bootstrap"])
    error_message = "All nodes must have a role of either 'server', 'agent', or 'bootstrap'."
  }

  validation {
    condition     = anytrue([for name, node in var.nodes : node.role == "bootstrap"])
    error_message = "At least one node must be defined with the role 'bootstrap'."
  }
}

# Global Overrides
variable "k3s_version" {
  type        = string
  default     = null
  description = "Version of k3s to install. Should be a version tag as found on the k3s GitHub repository (https://github.com/k3s-io/k3s/releases)."
}

variable "labels" {
  type        = list(string)
  default     = []
  description = "Default labels to apply to all nodes."
}

variable "taints" {
  type        = list(string)
  default     = []
  description = "Default taints to apply to all nodes."
}

variable "uninstall_on_destroy" {
  type        = bool
  default     = true
  description = "Uninstall k3s on nodes when the Terraform resources are destroyed."
}

variable "additional_k3s_args" {
  type        = list(string)
  default     = []
  description = "Additional arguments to pass to the k3s installer."
}

# Global Configuration
variable "fixed_registration_host" {
  type        = string
  default     = null
  description = "External load balancer hostname or address for communication with k3s servers in an HA configuration."
}

variable "datastore_endpoint" {
  type        = string
  default     = null
  description = "Specify external datastore endpoint. Postgres (postgres://), MySQL/MariaDB (mysql://), or etcd (https://)."

  validation {
    condition     = var.datastore_endpoint == null || can(regex("^(postgres://|mysql://|https://)", var.datastore_endpoint))
    error_message = "Datastore endpoint must be a valid connection string for Postgres (postgres://), MySQL/MariaDB (mysql://), or etcd (https://)."
  }
}

variable "enable_embedded_etcd" {
  type        = bool
  default     = false
  description = "Enable embedded etcd. Requires an odd number of servers greater than 1. Disables SQLite. Cannot be used with datastore_endpoint."
}

variable "flannel_backend" {
  type        = string
  default     = "vxlan"
  description = "Flannel backend to use. Can be 'none', 'vxlan', 'host-gw', or 'wireguard-native'."

  validation {
    condition     = var.flannel_backend == "none" || var.flannel_backend == "vxlan" || var.flannel_backend == "host-gw" || var.flannel_backend == "wireguard-native"
    error_message = "Flannel backend must be one of 'none', 'vxlan', 'host-gw', or 'wireguard-native'."
  }
}

# Sensitive Variables
variable "ssh_private_key" {
  type        = string
  default     = null
  description = "SSH private key to use for connecting to nodes."
  sensitive   = true
}
