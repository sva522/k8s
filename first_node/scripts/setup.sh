#!/usr/bin/bash

declare -r rsc_dir='/home/admin/rsc'
declare -r output_dir='/tmp/gen' && mkdir -p "${output_dir}"

readonly admin_net=$1 && shift
readonly cni_net=$1   && shift
readonly vsan_net=$1  && shift
readonly svc_net=$1   && shift
readonly nc_ip=$1     && shift
readonly nc_port=$1   && shift

close_nc_pipe(){ killall nc; }
if [[ -n "${nc_ip}" && -n "${nc_port}" ]]; then
    exec > >(nc "$nc_ip" "$nc_port") 2>&1
    trap close_nc_pipe EXIT INT TERM
fi
echo -n 'Wait for end of cloud init: '
cloud-init status --wait

readonly blue='\e[34;1m'
readonly nocolor='\e[0m'
title(){
    echo -ne "$blue"
    figlet -w 180 "$@"
    echo -ne "$nocolor"
}
shopt -s expand_aliases
alias bat='batcat --color=always'
alias diff='diff  --color=always'

title NETWORK TEST #########################################################################
ip -brief a
wait_for_ntp || exit 33
ping -W 1 -c 1 google.com || exit 50
hostname && hostname -f && [[ $(hostname) ==  $(hostname -f) ]] && exit 51

title GET NETWORK INFO ########################################################################

# 192.168.1.0/24 -> 192.168.1
network_get_prefix(){
    awk -F '.' '{print $1 "." $2 "." $3}' <<< "$1"
}

ip_from_net(){
    local -r network=$1
    local -r net_prefix=$(network_get_prefix "${network}")
    ip a | grep "${net_prefix}" | awk '{print $2}' | awk -F '/' '{print $1}'
}

interface_from_ip(){
    local -r ip=$1
    ip -brief a | grep "${ip}/" | awk '{print $1}'
}

readonly net_log="${output_dir}/net.log"
ip -brief a > "$net_log"
ip route   >> "$net_log" && echo >> "$net_log"
net_echo(){ echo "$@" | tee -a "$net_log"; }

readonly nat_ip=$(ip route show default | awk '{print $3}')
net_echo "Nat ip is: ${nat_ip}"
readonly admin_net_dns=$(dig "dns.${admin_net}" +short)
readonly admin_net_prefix=$(network_get_prefix "$admin_net_dns")
readonly admin_ip=$(ip_from_net "$admin_net_prefix")
readonly admin_if=$(interface_from_ip "$admin_ip")
readonly cluster_vip="${admin_net_prefix}.1"

net_echo "Admin ip is: ${admin_ip} on ${admin_if}, vip: ${cluster_vip}"
[ -z "${admin_ip}" ] && exit 10
ip -brief address show dev "${admin_if}" | grep -q "${admin_ip}/" || exit 1

readonly cni_net_dns=$(dig "dns.${cni_net}" +short)
readonly cni_ip=$(ip_from_net "$cni_net_dns")
readonly cni_if=$(interface_from_ip "$cni_ip")
net_echo "CNI ip is ${cni_ip} on ${cni_if}."
ip -brief address show dev "${cni_if}" | grep -q "${cni_ip}" || exit 2

readonly vsan_net_dns=$(dig "dns.${vsan_net}" +short)
readonly vsan_ip=$(ip_from_net "$vsan_net_dns")
readonly vsan_if=$(interface_from_ip "$vsan_ip")
net_echo "vSAN ip is ${vsan_ip} on ${vsan_if}."
ip -brief address show dev "${vsan_if}" | grep -q "${vsan_ip}" || exit 3

readonly svc_net_dns=$(dig "dns.${svc_net}" +short)
readonly svc_net_prefix=$(network_get_prefix "${svc_net_dns}")
readonly svc_ip=$(ip_from_net "$svc_net_prefix")
readonly svc_if=$(interface_from_ip "$svc_ip")
readonly svc_vip="${svc_net_prefix}.1"
net_echo "Service ip is: ${svc_ip} on ${svc_if}, vip: ${svc_vip}"
ip -brief address show dev "${svc_if}" | grep -q "${svc_ip}" || exit 4

# Update /etc/hosts to boostrap controlEndPoint
readonly controlEndPoint='k8s.lab.ln'
sed -i '/^# The following lines are desirable for IPv6 capable hosts/,$d' /etc/cloud/templates/hosts.debian.tmpl # Remove ipv6 lines
sed -i '/^$/d' /etc/cloud/templates/hosts.debian.tmpl  # Remove empty lines
echo "127.0.0.1 $controlEndPoint" >> /etc/cloud/templates/hosts.debian.tmpl
cloud-init single --name update_etc_hosts

# Ensure containerd is running
until ctr version &>/dev/null; do sleep 2; done
# Force configuration of node-ip
#echo "KUBELET_EXTRA_ARGS=--node-ip=${admin_ip}" > /etc/default/kubelet && systemctl enable kubelet

title PULLING IMAGES #######################################################################
kube-vip version
kubeadm config images pull

title KUBEADM INIT #########################################################################
kubeadm_init(){
    # control-plane-endpoint : cluster endpoint (will use /etc/hosts fake bootstrap VIP)
    # apiserver-advertise-address: Node IP
    # apiserver-cert-extra-sans: Add certSANS
    # By default hostname and control-plane-endpoint are set in certSAN

    #kubeadm init --config="${rsc_dir}/kubeadm-init.yaml" --dry-run
    kubeadm init --config="${rsc_dir}/kubeadm-init.yaml" --upload-certs #--v=5
}
kubeadm_init | tee "${output_dir}/kube_adm_init.log" || exit $?
cat /etc/kubernetes/admin.conf > /root/.kube/config

# kube-apiserver
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -text | grep -A1 "Subject Alternative Name"
# etcd serveur
openssl x509 -in /etc/kubernetes/pki/etcd/server.crt -noout -text | grep -A1 "Subject Alternative Name"
# etcd peer
openssl x509 -in /etc/kubernetes/pki/etcd/peer.crt -noout -text | grep -A1 "Subject Alternative Name"

# Setup unique bind address on API server :
# It's a bad idea because apiserver must listen on both admin_ip and vip
#"${rsc_dir}/configureKubeApiServer.py" && systemctl restart kubelet
until kubectl get nodes &>/dev/null; do sleep 5; done
kubectl get nodes -o wide

title CALICO INSTALL ###################################################################################

crd_wait(){
    crd=$1
    echo "Waiting for CRD $crd to be created..."
    until kubectl get crd "$crd" >/dev/null 2>&1; do sleep 2; done
    kubectl wait --for=condition=Established "crd/$crd" --timeout=60s
}

calico_wait(){
    kubectl rollout status deployment/tigera-operator -n tigera-operator --timeout=180s
    kubectl wait --for=condition=Available  deployment/tigera-operator -n tigera-operator --timeout=180s
    crd_wait installations.operator.tigera.io
    crd_wait apiservers.operator.tigera.io
}

kubectl create -f 'https://raw.githubusercontent.com/projectcalico/calico/v3.30.3/manifests/tigera-operator.yaml'
calico_wait

wget -q 'https://raw.githubusercontent.com/projectcalico/calico/v3.30.3/manifests/custom-resources.yaml'
cp custom-resources.yaml /dev/shm
"${rsc_dir}/configureCalico.py" \
    --file custom-resources.yaml \
    --interface "${cni_if}" \
    --cidr '10.10.0.0/16'
diff /dev/shm/custom-resources.yaml custom-resources.yaml
kubectl create -f custom-resources.yaml

kubectl wait --for=condition=Ready "node/$(hostname)" --timeout 180s
#kubectl taint nodes --all node-role.kubernetes.io/control-plane:NoSchedule- # Put in InitConfiguration
kubectl label node --all node-role.kubernetes.io/worker=worker --overwrite
kubectl get nodes -o wide
#ss -tlpn | grep -E '0\.0\.0\.0:[0-9]+' | grep -v sshd

title CSR APPROVER #############################################################################################################
helm repo add kubelet-csr-approver https://postfinance.github.io/kubelet-csr-approver
helm install kubelet-csr-approver kubelet-csr-approver/kubelet-csr-approver -n kube-system -f "$rsc_dir/kubelet-csr-approver.yaml"

echo 'CSR after kubelet-csr-approver install:'
kubectl get csr
if kubectl get csr | grep -iq pending; then
    echo 'Wait for full approbation...'
    while kubectl get csr | grep -iq pending; do sleep 5; done
fi
kubectl get csr
if kubectl get csr | grep -iq denied; then
    kubectl get csr | grep -i denied | awk '{print $1}' | xargs -r kubectl describe csr
    kubectl -n kube-system logs deploy/kubelet-csr-approver # && sleep 3600 # debug
    exit 78
fi

title KUBE VIP INSTALL ##############################################################################################################
mkdir -p /etc/kubernetes/manifests/
kubectl apply -f 'https://kube-vip.io/manifests/rbac.yaml'

kube-vip_with_lb(){
    kube-vip manifest daemonset \
    --controlplane \
    --interface "${admin_if}" \
    --address "${cluster_vip}" \
    --vipSubnet '24' \
    --inCluster \
    --taint \
    --arp \
    --leaderElection \
    --services \
    --serviceInterface "${svc_if}" \
    --servicesElection > kube-vip.yaml
}
# To remove LB remove services, serviceInterface, servicesElection
kube-vip_admin_only(){
    kube-vip manifest daemonset \
    --controlplane \
    --interface "${admin_if}" \
    --address "${cluster_vip}" \
    --vipSubnet '24' \
    --inCluster \
    --taint \
    --arp \
    --leaderElection > kube-vip.yaml
}
kube-vip_with_lb
"${rsc_dir}/configureKubeVip.py" kube-vip.yaml
kubectl create -f kube-vip.yaml
kubectl rollout status daemonset/kube-vip-ds -n kube-system --timeout=120s
echo "Waiting cluster vip ${cluster_vip} to be set on ${admin_if}..."
until ip -brief address show dev "${admin_if}" | grep -q "${cluster_vip}/"; do sleep 1; done
ip -brief address show dev "${admin_if}"

kube-vip_svc_vip_test(){
    # Test services vip
    kubectl create deployment test-nginx --image=nginx
    kubectl rollout status deployment/test-nginx --timeout=30s
    cp "${rsc_dir}/ServiceTest.yaml" .
    sed -i "s/<svc_vip>/${svc_vip}/" ServiceTest.yaml
    kubectl apply -f ServiceTest.yaml
    kubectl get svc test-service -o wide
    echo 'Waiting test-service external ip to set...'
    while kubectl get svc test-service -o wide | grep -q '<pending>'; do sleep 2; done
    kubectl get svc test-service -o wide
    echo "Waiting service vip ${svc_vip} to be set on ${svc_if}..."
    until ip -brief address show dev "${svc_if}" | grep -q "${svc_vip}/"; do sleep 1; done
    ip -brief address show dev "${svc_if}"
    echo "Waiting service to be available (https)..."
    until curl -s "${svc_vip}" | grep -q '<title>'; do sleep 1; done
    curl -s "${svc_vip}" | grep '<title>'
    kubectl delete svc test-service
    kubectl delete deployment test-nginx
}
grep -q "$svc_if" kube-vip.yaml && kube-vip_svc_vip_test

# Save kubeconfig
cp /etc/kubernetes/admin.conf "${output_dir}/kube_config.conf"
sed "s/$controlEndPoint:/$admin_ip:/" "${output_dir}/kube_config.conf" > "${output_dir}/kube_first_node.conf"
chown -R admin:admin "${output_dir}"

# Setup local kubeconfig
cat /etc/kubernetes/admin.conf > /root/.kube/config
cat /etc/kubernetes/admin.conf > /home/admin/.kube/config && chown admin:admin /home/admin/.kube/config
# Purge local kubectl cache
rm -rf ~/.kube/cache ~/.kube/http-cache
kubectl get nodes -o wide
sudo -u admin kubectl get nodes -o wide

title METRICS SERVER ##############################################################################################################
# Install metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl rollout status deployment metrics-server -n kube-system
echo 'Wait for metrics server...'
until kubectl top nodes &>/dev/null; do sleep 1; done
kubectl top nodes

title FINISHED !
