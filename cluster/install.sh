#!/usr/bin/bash
set -euo pipefail

cd "$(dirname "$0")"
source "../functions.sh"

# default: full cluster with 3 nodes
full_cluster=true
# Else -single -> cluster mono node (8Go de RAM)
if [ -v 1 ]; then full_cluster=false; fi
readonly full_cluster

readonly input_dir="${PWD}/input"
rm -rf "$input_dir" && mkdir -p "$input_dir"

readonly first_node_path="${project_dir}/first_node/output"
readonly first_node_img_path="${first_node_path}/k8s1.qcow2.xz"
readonly first_node_img_name=$(basename "$first_node_img_path")
readonly first_node_qcow2_path="${input_dir}/${first_node_img_name%.xz}" # remove .xz

readonly node_img_path="${project_dir}/k8s_base/output/k8s_base.qcow2.xz"
readonly node_img_name=$(basename "$node_img_path")
readonly node_qcow2_path="${input_dir}/${node_img_name%.xz}" # remove .xz

readonly conf_dir="${first_node_path}/gen"
readonly planning_file="$input_dir/planning.tfb"

source scripts/net_conf.sh

prepare_nodes(){
    unxz -c -v "$node_img_path" > "$node_qcow2_path"
    "$tools_dir/grow_vm.sh" "$node_qcow2_path" "$node_disk_size"

    # echo "Injecting some files..."
    # virt-copy-in -a "$node_qcow2_path"   \
    #     "$conf_dir/kube_config.conf"     \
    #     "$conf_dir/kube_first_node.conf" \
    #     /root/ 
}

prepare_first_node(){
    unxz -c -v "$first_node_img_path" > "$first_node_qcow2_path"
}

scripts/start_infra.sh &
prepare_first_node &
if $full_cluster; then
    prepare_nodes  &
fi
wait

# Print libvirt current state
./status.sh
if [ -n "$(find /etc/libvirt/qemu/ -name 'k8s*')" ]; then
    find /etc/libvirt/qemu/ -name 'k8s*' && exit 1
fi

tofu init
if $full_cluster; then
    tofu plan -out="$planning_file"
else
    tofu plan -var="node_count=1" -var="node_ram_mb=8096" -out="$planning_file"
fi
tofu apply -auto-approve "$planning_file"
libvirt_allow_nat
./status.sh

## POST LAUNCH CHECKS ##############################################################################################

wait_for_ping(){
    hostname="$1"
    ip="$2"
    echo -n "Wait for ping $hostname... "
    until ping -q -W 1 -c 1 "$ip" &>/dev/null; do sleep 5; done
    echo "[OK]"
}
readonly k8s1_ip=$(dig k8s1 +short "@$dns_vm_admin")
readonly k8s2_ip=$(dig k8s2 +short "@$dns_vm_admin")
readonly k8s3_ip=$(dig k8s3 +short "@$dns_vm_admin")

wait_for_ping k8s1 "$k8s1_ip"
if $full_cluster; then
    wait_for_ping k8s2 "$k8s2_ip"
    wait_for_ping k8s3 "$k8s3_ip"
fi

wait_for_ssh k8s1 "$k8s1_ip"
if $full_cluster; then
    wait_for_ssh k8s2 "$k8s2_ip"
    wait_for_ssh k8s3 "$k8s3_ip"
fi

echo "Wait for node availability..."
k_get_node_rescue(){
    kubectl --kubeconfig="${conf_dir}/kube_first_node.conf" get nodes -o wide
}
until k_get_node_rescue 2>&1 | grep -q '^NAME' &>/dev/null; do sleep 5; done
k_get_node_rescue
echo

echo "Wait for cluster availability..."
k_get_node(){
    kubectl --kubeconfig="${conf_dir}/kube_config.conf" get nodes -o wide
}
until k_get_node &>/dev/null; do sleep 5; done
k_get_node
echo

wait_for_ping 'cluster VIP' "$k8s1_ip"

## JOIN ##################################################################################
if $full_cluster; then
    readonly kubeadm_join_args=$(cat scripts/kubeadm_join_args.sh | ssh "admin@$k8s1_ip" 'sudo bash -s')
    echo "/dev/shm/kubeadm_join.sh $kubeadm_join_args"

    kubeadm_join(){
        node_name="$1"
        node_ip="$2"
        echo "Joining $node_name..."
        scp -q rsc/*.yaml "admin@${node_ip}:/dev/shm"
        cat scripts/kubeadm_join.sh | ssh "admin@$node_ip" "sudo bash -s -- $kubeadm_join_args"
    }

    kubeadm_join 'k8s2' "$k8s2_ip" &
    kubeadm_join 'k8s3' "$k8s3_ip" &
    wait
fi

echo 'On host: --------------------------------'
kubectl get nodes -o wide

# Alternative SANs:
# kubectl config set-cluster kubernetes --server=https://192.168.11.11:6443
