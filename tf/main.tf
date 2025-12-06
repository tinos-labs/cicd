module "digitalocean" {
  source       = "https://${var.gh_pat}@github.com/tinos-labs/terraform_modules.git//digitalocean?ref=main"

  providers = {
    digitalocean = digitalocean
  }

  cluster_name = "sirius"
  k0s_nodes = var.k0s_nodes
  user_data = file("${path.module}/cloud_init.yaml")
} 


module "k0sctl" {
  source = "https://${var.github_token}@github.com/tinos-labs/terraform_modules.git//k0sctl?ref=main"

  ssh_key_path = var.ssh_key_path
  cluster_name    = var.cluster_name
  user            = var.user
  kubeconfig_path = var.kubeconfig_path

  k0s_hosts    = module.digitalocean.k0s_hosts

  depends_on = [ module.digitalocean ]
}


module "flux_operator" {
  source = "https://${var.github_token}@github.com/tinos-labs/terraform_modules.git//flux_operator?ref=main"

  providers = {
    kubernetes = kubernetes
    helm       = helm
  }

  git_path = var.git_path
  git_url  = var.git_url
  github_app_id = var.github_app_id
  github_app_installation_id = var.github_app_installation_id
  github_app_pem = var.github_app_pem

  depends_on = [ module.k0sctl ]
}


module "infrastructure" {
  source = "https://${var.github_token}@github.com/tinos-labs/terraform_modules.git//infrastructure?ref=main"

   providers = {
    helm       = helm
    kubectl    = kubectl
  }

  traefik_ip = module.digitalocean.traefik_ip

  node_labels = {
    for node_name, node in var.k0s_nodes :
    "${var.cluster_name}-${node_name}-${join("", [for r in split("+", node.role) : substr(r, 0, 1)])}" => merge(
      {
        size = node.size
        role = node.role
      },
      node.labels
    )
  }
 
  depends_on = [ module.k0sctl ]
}