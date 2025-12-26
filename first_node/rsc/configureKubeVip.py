#!/usr/bin/env python3

import yaml
from sys import argv

file_path = argv[1]

# Read whole file
with open(file_path) as f:
    content = f.read()

# I) Remove everything before apiVersion (if any)
index = content.find('apiVersion:')
if index != -1:
    content = content[index:]

# Read yaml
conf = yaml.safe_load(content)
spec = conf['spec']['template']['spec']

# II) Remove warning deprecated for node-role.kubernetes.io/master
nodeAffinity = spec['affinity']['nodeAffinity']
nodeSelectorTerms = nodeAffinity['requiredDuringSchedulingIgnoredDuringExecution']['nodeSelectorTerms']
for nodeSelectorTerm in nodeSelectorTerms.copy():
    matchExpressions = nodeSelectorTerm['matchExpressions']
    for matchExpression in matchExpressions.copy():
        if matchExpression['key'] == 'node-role.kubernetes.io/master':
            matchExpressions.remove(matchExpression)
    if not matchExpressions:
        nodeSelectorTerms.remove(nodeSelectorTerm)

# III) Try to force disable bgp
spec['containers'][0]['env'].append({'name': 'bgp_enable', 'value': 'false'})

# Inplace modification
with open(file_path, 'w') as f:
        yaml.dump(conf, f, default_flow_style=False)
