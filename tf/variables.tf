variable "do_token" {
  description = "DigitalOcean API Token"
  type        = string
  sensitive   = true
}

variable "gh_pat" {
  description = "Github Personal Access Token"
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  description = "Cluster Name"
  type        = string
}

variable "k0s_nodes" {
  description = "Map of K0s nodes with their roles and droplet size"
  type = map(object({
    role   = string
    size = string
    labels = optional(map(string), {})
  }))
}

variable "user" {
  description = "Username for SSH connections to K0s nodes"
  type        = string
  default     = "k0sadmin"
}

variable "ssh_key_path" {
  description = "SSH key path to access K0s nodes"
  type        = string
  nullable    = true
  default     = ""
}

variable "kubeconfig_path" {
  type = string
}

variable "github_app_id" {
  description = "GitHub App ID"
  type        = string
}

variable "github_app_installation_id" {
  description = "GitHub App Installation ID"
  type        = string
}

variable "github_app_pem" {
  description = "The contents of the GitHub App private key PEM file"
  sensitive   = true
  type        = string
}

variable "git_url" {
  description = "Git repository URL"
  type        = string
  nullable    = false
}

variable "git_path" {
  description = "Path to the cluster manifests in the Git repository"
  type        = string
  nullable    = false
}
