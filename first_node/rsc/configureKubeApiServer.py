#!/usr/bin/env python3

import yaml
from sys import argv

file_path = '/etc/kubernetes/manifests/kube-apiserver.yaml'

# Read whole file
with open(file_path) as f:
    conf = yaml.safe_load(f)

# Find main_container
container = None
for c in conf['spec']['containers']:
    if c['name'] == 'kube-apiserver':
        container = c

# Remove enventual bind_address
new_tokens = []
for token in container['command']:
    if not token.startswith('--bind-address'):
        new_tokens.append(token)
container['command'] = new_tokens

# Find advertise-address
advertise_address = None
new_tokens = []
for token in container['command']:
     if token.startswith('--advertise-address'):
          advertise_address=token.split('=')[1]
          break

if advertise_address is None:
    advertise_address = argv[1]

# Add bind-address
container['command'].insert(1, '--bind-address=' + advertise_address)

# Inplace modification
with open(file_path, 'w') as f:
        yaml.dump(conf, f, default_flow_style=False)
