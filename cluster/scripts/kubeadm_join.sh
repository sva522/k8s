#!/usr/bin/bash

cd "$(dirname $0)"

readonly join_token="$1"
readonly dicovery_token="$2"
readonly certificate_key="$3"
readonly join_config_file_path='/dev/shm/kubeadm-join.yaml'
readonly init_config_file_path='/dev/shm/kubeadm-init.yaml'

echo -n 'Wait for end of cloud init: '
cloud-init status --wait

readonly admin_net='vm_admin'
readonly admin_net_dns=$(dig "dns.${admin_net}" +short)
readonly admin_ip=$(dig "$HOSTNAME" "@${admin_net_dns}" +short)

wait_for_ntp
echo 'Wait for containerd...'
until ctr version &>/dev/null; do sleep 5; done

echo 'Pulling kubeadm images...'
kubeadm config images pull

# Perform join
if [ -f "$join_config_file_path" ]; then
    set_conf(){ 
        sed -i "s/<$1>/$2/g" "$join_config_file_path";
        sed -i "s/<$1>/$2/g" "$init_config_file_path";
    }
    set_conf 'fqdn'                   "$(hostname -f)"
    set_conf 'hostname'               "$HOSTNAME"
    set_conf 'control_plane_endpoint' 'k8s.lab.ln'
    set_conf 'admin_ip'               "$admin_ip"
    set_conf 'join_token'             "$join_token"
    set_conf 'dicovery_token'         "$dicovery_token"
    set_conf 'certificate_key'        "$certificate_key"
    kubeadm join "--config=$join_config_file_path" --v=5
    mv "$join_config_file_path" /root
    mv "$init_config_file_path" /root
    
else
    kubeadm join k8s.lab.ln:6443 \
    --token "$join_token" \
    --discovery-token-ca-cert-hash "$dicovery_token" \
    --control-plane \
    --certificate-key "$certificate_key" \
    --apiserver-advertise-address "$admin_ip" \
    --apiserver-cert-extra-sans "k8s2,k8s2.lab.ln,k8s.lab.ln,127.0.0.1,$admin_ip" \
    #--v=5
fi

# Setup kubeconfig
cat /etc/kubernetes/admin.conf > /root/.kube/config
cat /etc/kubernetes/admin.conf > /home/admin/.kube/config && chown admin:admin /home/admin/.kube/config


# Check cluster local availability (vip) #######################
if kubectl get nodes &>/dev/null; then
    echo 'Cluster status by vip as root is [OK]'
else
    echo 'Cluster status by vip as root is [KO]'
fi
if sudo -u admin kubectl get nodes -o wide &>/dev/null; then
    echo 'Cluster status by vip as admin is [OK]'
else
    echo 'Cluster status by vip as admub is [KO]'
fi

# Check cluster local availability (127.0.0.1) #######################
if ! grep -q k8s.lab.ln /etc/hosts; then
    sed -i '/^# The following lines are desirable for IPv6 capable hosts/,$d' /etc/cloud/templates/hosts.debian.tmpl # Remove ipv6 lines
    sed -i '/^$/d' /etc/cloud/templates/hosts.debian.tmpl  # Remove empty lines
    echo '127.0.0.1 k8s.lab.ln' >> /etc/cloud/templates/hosts.debian.tmpl
fi
cloud-init single --name update_etc_hosts
if kubectl get nodes &>/dev/null; then
    echo 'Cluster status on localhost as root is [OK]'
else
    echo 'Cluster status on localhost as root is [KO]'
fi

if sudo -u admin kubectl get nodes -o wide &>/dev/null; then
    echo 'Cluster status on localhost as admin is [OK]'
else
    echo 'Cluster status on localhost as admub is [KO]'
fi

echo 'Waiting for node Ready status...'
kubectl wait --for=condition=Ready "node/$(hostname)" --timeout=180s
kubectl label node --all node-role.kubernetes.io/worker=worker --overwrite

kubeadm_add_certSANs "$(hostname -f)" "$admin_ip"
#kubectl get nodes -o wide
