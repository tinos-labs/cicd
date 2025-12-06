provider "digitalocean" {
  token = var.do_token
}

provider "kubernetes" {
  config_path = module.k0sctl.kubeconfig_path

}

provider "helm" {
  kubernetes {
    config_path = module.k0sctl.kubeconfig_path
  }
}

provider "kubectl" {
  config_path = module.k0sctl.kubeconfig_path
}