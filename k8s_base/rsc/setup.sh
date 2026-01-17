#!/bin/bash
cd "$(dirname "$0")"

ip=$1
port=$2

# Redirect stdout to host
echo "STARTING $0 ---------------------------------------"
# Setting output to host console
until ping -q -W 1 -c 1 "$ip" &>/dev/null; do sleep 2; done
apt-get update -qq
apt-get install -yqq netcat-openbsd
exec > >(nc "$ip" "$port") 2>&1

## Installing figlet for fancy title ##################################################
readonly blue='\e[34;1m'
readonly nocolor='\e[0m'
title(){
    echo -ne "$blue"
    figlet -w 180 "$@"
    echo -ne "$nocolor"
}
export DEBIAN_FRONTEND=noninteractive
echo -e "${blue}Starting setup...${nocolor}"
apt-get install -qqy figlet

title INSTALL PACKAGES ##################################################################
apt-get purge -y --autoremove tcpdump systemd-timesyncd screen reportbug socat vim vim-tiny apparmor
rm -rf /etc/apparmor*

apt-get upgrade -qq

# apt-get install -qqy \
# - debian "nocloud" image does not include those packages
# - basic packages
# - python yaml packages
# - apt security packages
# - longhorn dependency
apt-get install -qqy openssh-server cloud-init \
    htop curl wget dnsutils jq nano chrony console-setup qemu-guest-agent bat \
    python3 python3-yaml python3-ruamel.yaml python3-tomlkit \
    apt-transport-https ca-certificates gpg \
    open-iscsi

# Enable iscsid for longhorn
systemctl enable iscsid

# Enable hypervisor integration
systemctl enable qemu-guest-agent

title CONFIGURE NTP #########################################################################
# Install wait_for_ntp service
cp wait_for_ntp.sh      /usr/local/bin/wait_for_ntp
cp wait_for_ntp.service /etc/systemd/system/
systemctl enable wait_for_ntp

# Setup wait_for_ntp precondition on ssh service
mkdir -p /etc/systemd/system/ssh.service.d
cp wait_ntp_override.conf /etc/systemd/system/ssh.service.d

# Enable ntp
cat chrony.conf > /etc/chrony/chrony.conf
systemctl enable chrony

title CONFIGURE SSH #########################################################################
cp sshd.conf          /etc/ssh/sshd_config.d/00-setup.conf
cp gen_sshd_listen.sh /usr/local/bin/gen_sshd_listen
#cp gen_sshd_listen.service /etc/systemd/system/
#cp gen_sshd_listen_override.conf /etc/systemd/system/sshd.service.d/
#systemctl enable gen_sshd_listen

title SYSTEM CONFIG #####################################################################################
# Create admin account for debug (Pefer using cloud-init)
./create_admin.sh "$(cat packer.pub)" '$6$B8vK7R25sy.C9ltV$iS0TAhj0.Jl3uNlukNveOaNsh6ItYNemQcPySS0Knr4TE95JRa6RDglwldoKPKTU5OXFz7PFzg./DoOxexSKo0'
# cp netplan.yaml /etc/netplan/99-default.yaml # default network conf for debugging

# Remove and lock root password
passwd -l root
chsh -s /usr/sbin/nologin root

# Set french keyboard
cat > /etc/default/keyboard << EOF
XKBMODEL="pc105"
XKBLAYOUT="fr"
XKBVARIANT=""
XKBOPTIONS=""
EOF
sed -i 's/^KEYMAP=.*$/KEYMAP=fr/'              /etc/initramfs-tools/initramfs.conf
sed -i 's/^COMPRESS=.*/COMPRESS=xz/'           /etc/initramfs-tools/initramfs.conf
sed -i 's/# COMPRESSLEVEL=.*/COMPRESSLEVEL=9/' /etc/initramfs-tools/initramfs.conf
update-initramfs -u

# Enable bash completion
sed -i '/^#if ! shopt -oq posix/,/^#fi/ s/^#//' /etc/bash.bashrc
cat bashrc_append.sh  >> /etc/bash.bashrc
mkdir /root/.kube
mkdir /home/admin/.kube && chown admin:admin /home/admin/.kube
cat nanorc            >  /etc/nanorc
echo > /etc/motd # Remove motd

cat sysctl-k8s.conf       > /etc/sysctl.d/k8s.conf
cat grub.cfg > /etc/default/grub.d/custom.cfg && update-grub
systemctl enable --now serial-getty@ttyS0.service # enable serial console
cat k8s-modprobe.conf     > /etc/modules-load.d/k8s.conf

# Set generic hostname
cat > /etc/hosts << EOF
127.0.0.1       localhost
127.0.1.1       debian
EOF
echo debian > /etc/hostname

# On nocloud image ssh-keygen is not installed (from openssh-client package)
# So that sshd host key has not been installed. This is required for sshd to start
#groupadd ssh
#apt-get install -yqq openssh-client
#ssh-keygen -A

title INSTALL CONTAINERD #########################################################################
# Install containerd with cgroups handled by systemd
# Avoid containerd to be launched after install
apt-get install -y containerd
mkdir -p /etc/containerd/certs.d/
cp -r registries/* /etc/containerd/certs.d
containerd config default > /etc/containerd/config.toml
./configureContainerd.py '/etc/containerd/config.toml'

# Debian provides the containernetworking-plugins package, which provides a basic CNI for single-node clusters.
# This CNI is available in /usr/lib/cni. Debian's containerd will therefore look for the CNI in /usr/lib/cni instead of /opt/cni/bin (the default for CALICO).
ln -s /opt/cni/bin /usr/lib/cni

title INSTALL KUBELET #########################################################################
# Add k8s key
readonly k8s_version=v1.34
curl -fsSL https://pkgs.k8s.io/core:/stable:/${k8s_version}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${k8s_version}/deb/ /" > /etc/apt/sources.list.d/kubernetes.list
apt-get update -qq

## Install kube packages ####
# Avoid kubelet to be launched after install
#systemctl mask kubelet (comment-out because useless in chroot)
apt-get install -yqq kubelet kubeadm kubectl
#systemctl disable kubelet # will be started for the first time by kubeadm init
systemctl enable kubelet

# Wait for ntp before kubelet
mkdir -p /etc/systemd/system/kubelet.service.d
cp wait_ntp_override.conf /etc/systemd/system/kubelet.service.d/

# Use systemd cgroups
cat kubelet-config.yaml > /var/lib/kubelet/config.yaml

# Install helm
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" > /etc/apt/sources.list.d/helm-stable-debian.list
apt-get update --no-audit -qq; apt-get install -yq helm

# Put kube-vip
./install_crictl.sh
mv kube-vip /usr/local/bin

# Install kubeadm_add_certSANs
mv kubeadm_add_certSANs.py /usr/local/bin/kubeadm_add_certSANs
cp root_ca.crt /usr/local/share/ca-certificates/root_ca.crt
update-ca-certificates

# Perform some cleanup
apt-get autoremove -yqq
apt-get clean
# Remove package list (will be regenerated by apt update)
rm -rf /var/lib/apt/lists/*
journalctl --vacuum-size=1G &>/dev/null
cd /root
rm -rf /root/rsc
