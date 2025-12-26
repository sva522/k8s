#cloud-config
hostname: ${hostname}
fqdn: ${fqdn}
manage_etc_hosts: true

# Keep rescue account in image
#users:
#  - name: admin
#    ssh_authorized_keys:
#      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH0u42ThkDDkM6sPXoCGzgpJ23EiW2fUo0cysnnGWGKr packer@k8s
#    sudo: ALL=(ALL) NOPASSWD:ALL
#    shell: /usr/bin/bash
#    lock_passwd: false
#    # openssl passwd -6 'rescue'
#    passwd: $6$B8vK7R25sy.C9ltV$iS0TAhj0.Jl3uNlukNveOaNsh6ItYNemQcPySS0Knr4TE95JRa6RDglwldoKPKTU5OXFz7PFzg./DoOxexSKo0

package_update: true
package_upgrade: true

# Executed once
#runcmd:
#  - |
#    wait_for_ntp
#    until ctr version &>/dev/null; do sleep 5; done

#final_message: "Cloud-init finished successfully."

# Debug with :
# cloud-init schema --system
# and cat /var/log/cloud-init.log | grep -i 'error\|fail'
