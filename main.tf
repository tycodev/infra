resource "random_id" "id" {
	  byte_length = 8
}
locals {
  instance_name="k3s-node-${substr(random_id.id.hex,0,6)}"
}

resource "proxmox_virtual_environment_vm" "k3s-node" {
  name      = local.instance_name
  node_name = "pve"

  agent {
    enabled = true
  }

  cpu {
    cores = 4
  }

  memory {
    dedicated = 4096
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 20
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id
  }

  network_device {
    bridge = "vmbr0"
  }

}

resource "proxmox_virtual_environment_download_file" "ubuntu_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve"

  url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
}

output "vm_ipv4_address" {
  value = proxmox_virtual_environment_vm.k3s-node.ipv4_addresses[1][0]
}