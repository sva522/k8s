#!/usr/bin/bash

readonly ssh_key="$1"
#admin_passwd_hash=$(openssl passwd -6 'rescue')
readonly passwd_hash="$2"

# Create admin account for debug (Pefer using cloud-init)

# Create account
useradd -m admin
chsh -s /usr/bin/bash     admin
usermod -p "$passwd_hash" 'admin'

# Add ssh key
mkdir -p /home/admin/.ssh && chmod 700 /home/admin/.ssh
echo "$ssh_key" > /home/admin/.ssh/authorized_keys
chmod 600 /home/admin/.ssh/authorized_keys

mkdir /home/admin/.kube
chown -R admin:admin /home/admin

# Set sudoers
usermod -a -G sudo admin
echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
