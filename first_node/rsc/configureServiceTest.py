#!/usr/bin/env python3

import yaml
from socket import getfqdn
from sys import argv


# Read whole file
with open('ServiceTest.yaml') as f:
    conf = yaml.safe_load(f)

conf['metadata']['annotations']['kube-vip.io/loadbalancerIPs'] = argv[1]
conf['metadata']['annotations']['kube-vip.io/vipHost']         = getfqdn()

# Inplace modification
with open('ServiceTest.yaml', 'w') as f:
        yaml.dump(conf, f, default_flow_style=False)
