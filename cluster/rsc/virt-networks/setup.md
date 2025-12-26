# List persistant and not persistant network
virsh net-list --all
# Accès "root" à virsh (par défaut qemu:///session est utilisé)
virsh -c qemu:///system net-list --all

# Creation ad-hoc (disparait au reboot)
virsh -c qemu:///system net-create vm_cni.xml

# Persistant après reboot
virsh -c qemu:///system net-define vm_cni.xml
virsh -c qemu:///system net-start vm_cni
virsh -c qemu:///system net-autostart vm_cni


virsh -c qemu:///system net-create vm_nat.xml

# Remove
virsh -c qemu:///system net-autostart --disable vm_cni
virsh -c qemu:///system net-undefine vm_cni
virsh -c qemu:///system net-destroy vm_cni



# Dans terraform :
# Suppose que default tourne déjà
network_interface {
    addresses    = ["192.168.122.101"]
    network_name = "default"
  }

# Ou creation du réseau dans terraform

resource "libvirt_network" "vm_nat" {
  name      = "vm_nat"
  mode      = "nat"
  domain    = "lab.ln"
  addresses = ["192.168.122.0/24"]

  dhcp {
    enabled = true
  }

  dns {
    enabled = true
  }
}

# Prise de controle :

virsh -c qemu:///system console k8s1

#graphics {
#  type           = "vnc" or spice
#  listen_type    = "address"
# listen_address = "127.0.0.1"
# autoport       = true
#}

# virsh vncdisplay k8s1 -> :0 5900 + 0
vncviewer 127.0.0.1:0
# From remote
ssh -L 5900:127.0.0.1:5900 user@hyperviseur
vncviewer 127.0.0.1:0
