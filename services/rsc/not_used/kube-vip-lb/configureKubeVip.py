#!/usr/bin/env python3

import yaml
from sys import argv

file_path = argv[1]

# Read whole file
with open(file_path) as f:
    content = f.read()

# Remove everything before apiVersion (if any)
index = content.find('apiVersion:')
if index != -1:
    content = content[index:]

# Set daemonset name
content = content.replace('kube-vip-ds', 'kube-vip-ds-admin-lb')

# Read yaml
conf = yaml.safe_load(content)
spec = conf['spec']['template']['spec']

# Environment variables
variables = spec['containers'][0]['env']
# Main container args
container_args = spec['containers'][0]['args']

# Read environment variables
svc_if = None
for variable in variables:
     if variable['name'] == 'vip_servicesinterface':
         svc_if = variable['value']

# Remove useless default variables
variables.remove({"name": "port", "value": "6443"})

# Modify environment variables
variables.append({'name': 'bgp_enable', 'value': 'false'}) # Force no bgp

# With this configuration kube-vip seems to ignore env var vip_servicesinterface WTF ??? (ex: vip_servicesinterface)
# Put it directly in container args
variables.remove({"name": "vip_servicesinterface", "value": svc_if})
container_args.append('--serviceInterface=' + svc_if)
# In doubt I do the same with lbClassOnly
variables.remove({"name": "lb_class_only", "value": "true"})
container_args.append('--lbClassOnly')

# lbClassName and lbClassNameLegacyHandling are ignored (not added) during manifest generation
# Adding them as env vars seems to have no effect... Put them directly in containers args
container_args.append('--lbClassName=kube-vip-admin-lb')
container_args.append('--lbClassNameLegacyHandling=false')

# Avoid conflict betwween multiple kube-vip instances by modifying those env vars
for variable in variables:
     if variable['name'] == 'svc_leasename':
         variable['value'] = 'plndr-svcs-lock-adm-lb'
     if variable['name'] == 'prometheus_server':
            prometheus_port =  variable['value'] .split(':')[-1]
            prometheus_port = int(prometheus_port) + 1
            variable['value'] = ':' + str(prometheus_port)

# Inplace modification
with open(file_path, 'w') as f:
        yaml.dump(conf, f, default_flow_style=False)
