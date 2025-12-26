terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.8.3"
    }
  }
}

provider "libvirt" {
  alias = "localhost"
  uri = "qemu:///system"
}

variable "first_node_img_path" {
  description = "first node qcow2 image path"
  default = "input/k8s1.qcow2"
}

variable "node_img_path" {
  description = "base node qcow2 image path"
  default = "input/k8s_base.qcow2"
}

variable "node_count" {
  description = "Number of node to be created (1 mono node, 3 full cluster)"
  type        = number
  default     = 3
}

variable "node_ram_mb" {
  description = "RAM per node (MB)"
  type        = number
  default     = 4096
}

resource "libvirt_network" "vm_nat" {
  provider = libvirt.localhost

  name      = "vm_nat"
  mode      = "nat"
  domain    = "lab.ln"
  addresses = ["192.168.10.0/24"]
  dhcp { enabled = true }
  dns  { enabled = true }
}

resource "libvirt_volume" "template_node" {
  provider = libvirt.localhost

  count = var.node_count > 1 ? 1 : 0 # Do not create if only one node
  name   = "k8s_base.qcow2"
  pool   = "default"
  source = var.node_img_path
  format = "qcow2"
}

resource "libvirt_volume" "node_disks" {
  provider = libvirt.localhost

  count  = var.node_count
  name   = "k8s${count.index + 1}.qcow2"
  pool   = "default"
  format = "qcow2"

  # If   Node 1   (index 0    | k8s1)       : Direct directly k8s1.qcow2
  # Else Node > 1 (index 1, 2 | k8s2, k8s3) : Use template base (Linked Clone).
  source = count.index == 0 ? var.first_node_img_path : null
  base_volume_id = count.index == 0 ? null : try(libvirt_volume.template_node[0].id, null)
}

resource "libvirt_cloudinit_disk" "cloud_init_disks" {
  provider = libvirt.localhost

  count = var.node_count
  name  = "k8s${count.index + 1}_cloud_init.iso"
  pool  = "default"

  user_data = templatefile("${path.module}/../cluster/cloud-init/user-data.tpl", {
    hostname = "k8s${count.index + 1}"
    fqdn     = "k8s${count.index + 1}.lab.ln"
  })
  
  meta_data = templatefile("${path.module}/../cluster/cloud-init/meta-data.tpl", {
    hostname = "k8s${count.index + 1}"
  })

  network_config = file("${path.module}/../cluster/cloud-init/network-config.yaml")
}

resource "libvirt_domain" "local" {
  provider = libvirt.localhost

  count  = var.node_count
  name   = "k8s${count.index + 1}"
  memory = var.node_ram_mb
  vcpu   = 4

  # Main disk
  disk {
    volume_id = libvirt_volume.node_disks[count.index].id
  }

  cloudinit = libvirt_cloudinit_disk.cloud_init_disks[count.index].id
  qemu_agent = true

  # vm_nat (IPs: .101, .102, .103)
  network_interface {
    network_id     = libvirt_network.vm_nat.id
    addresses      = ["192.168.10.${101 + count.index}"]
    wait_for_lease = true
  }

  network_interface { bridge = "vm_admin" }
  network_interface { bridge = "vm_cni" }
  network_interface { bridge = "vm_vsan" }
  network_interface { bridge = "vm_svc" }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}
