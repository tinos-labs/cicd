terraform {
    required_providers {
        digitalocean = {
            source  = "digitalocean/digitalocean"
            version = "~> 2.0"
        }
        kubernetes = {
            source  = "hashicorp/kubernetes"
            version = "~> 2.0"
        }
        helm = {
            source  = "hashicorp/helm"
            version = "~> 2.0"
        }
        kubectl = {
            source = "gavinbunney/kubectl"
            version = ">= 1.19.0"
        }
    }
    required_version = ">= 1.3.0"
}