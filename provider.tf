terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
    }
  }
}

provider "proxmox" {
  endpoint = var.virtual_environment_endpoint
  api_token = var.virtual_environment_token
  insecure = true
  ssh {
    agent = true
    username = var.virtual_environment_username
  }
}