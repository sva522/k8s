#!/usr/bin/env python3

from tomlkit import parse, dumps
from sys import argv
from os import symlink

file_path=argv[1]

with open(file_path) as f:
    content = f.read()
    config = parse(content)

# SystemdCgroup on runc
cri_plugin = 'io.containerd.grpc.v1.cri'
containerd_section = config['plugins'][cri_plugin].setdefault('containerd', {})
runtimes_section = containerd_section.setdefault('runtimes', {})
runc_section = runtimes_section.setdefault('runc', {})
options_section = runc_section.setdefault('options', {})
options_section['SystemdCgroup'] = True
# Do not set systemd_cgroup to true if key is present, this is legacy feature, which crash recent CRI

# This config is by default on containerd debian config file
# Insure it is setup debian way if confing has been rewritten someway
#opt_plugin = 'io.containerd.internal.v1.opt'
#if opt_plugin not in config['plugins']:
#    config['plugins'][opt_plugin] = {}
#config['plugins'][opt_plugin]['path'] = "/var/lib/containerd/opt"
#symlink('/var/lib/containerd/opt', '/opt/containerd')

# Configure registry
registry_section = config['plugins'][cri_plugin].setdefault('registry', {})
registry_section['config_path'] = '/etc/containerd/certs.d'

with open(file_path, 'w') as f:
    f.write(dumps(config))
