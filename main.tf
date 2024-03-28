data "template_file" "k3s-worker" {
  count = var.worker_node_count
  template = "$${hostname}"
  vars = {
    hostname = "k3s-worker-${count.index}"
  }
}

data "template_file" "k3s-master" {
  count = var.master_node_count
  template = "$${hostname}"
  vars = {
    hostname = "k3s-master-${count.index}"
  }
}

resource "proxmox_virtual_environment_vm" "k3s-worker-node" {
  count     = var.worker_node_count
  name      = data.template_file.k3s-worker[count.index].rendered
  node_name = "pve"

  agent {
    enabled = true
  }

  cpu {
    cores = 4
  }

  memory {
    dedicated = 7168
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 100
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_data_file_id = proxmox_virtual_environment_file.worker_node_cloud_config[count.index].id
  }

  network_device {
    bridge = "vmbr0"
  }
}

resource "proxmox_virtual_environment_vm" "k3s-master-node" {
  count     = var.master_node_count
  name      = data.template_file.k3s-master[count.index].rendered
  node_name = "pve"

  agent {
    enabled = true
  }

  cpu {
    cores = 2
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

    user_data_file_id = proxmox_virtual_environment_file.master_node_cloud_config[count.index].id
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

output "worker_vm_ipv4_address" {
  value = proxmox_virtual_environment_vm.k3s-worker-node[*].ipv4_addresses[1][0]
}

output "master_vm_ipv4_address" {
  value = proxmox_virtual_environment_vm.k3s-master-node[*].ipv4_addresses[1][0]
}