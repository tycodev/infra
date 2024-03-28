data "local_file" "ssh_public_key" {
  filename = var.virtual_machine_ssh_public_keyfile
}

resource "proxmox_virtual_environment_file" "worker_node_cloud_config" {
  count = var.worker_node_count
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve"

  source_raw {
    data = <<EOF
#cloud-config
hostname: ${data.template_file.k3s-worker[count.index].rendered}
users:
  - default
  - name: ubuntu
    groups:
      - sudo
    shell: /bin/bash
    ssh_authorized_keys:
      - ${trimspace(data.local_file.ssh_public_key.content)}
    sudo: ALL=(ALL) NOPASSWD:ALL
runcmd:
    - apt update
    - apt install -y qemu-guest-agent net-tools open-iscsi nfs-common linux-generic
    - timedatectl set-timezone America/New_York
    - systemctl enable qemu-guest-agent
    - systemctl start qemu-guest-agent
    - echo "done" > /tmp/cloud-config.done
    EOF

    file_name = "${data.template_file.k3s-worker[count.index].rendered}-cloud-config.yaml"
  }
}

resource "proxmox_virtual_environment_file" "master_node_cloud_config" {
  count = var.master_node_count
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve"

  source_raw {
    data = <<EOF
#cloud-config
hostname: ${data.template_file.k3s-master[count.index].rendered}
users:
  - default
  - name: ubuntu
    groups:
      - sudo
    shell: /bin/bash
    ssh_authorized_keys:
      - ${trimspace(data.local_file.ssh_public_key.content)}
    sudo: ALL=(ALL) NOPASSWD:ALL
runcmd:
    - apt update
    - apt install -y qemu-guest-agent net-tools open-iscsi nfs-common
    - timedatectl set-timezone America/New_York
    - systemctl enable qemu-guest-agent
    - systemctl start qemu-guest-agent
    - echo "done" > /tmp/cloud-config.done
    EOF

    file_name = "${data.template_file.k3s-master[count.index].rendered}-cloud-config.yaml"
  }
}