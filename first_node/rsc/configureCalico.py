#!/usr/bin/env python3

import yaml
from sys import argv
from argparse import ArgumentParser

def parse_args():
    parser = ArgumentParser(
        description='Set interface and CIDR network to calico custom resources manifest.'
    )
    parser.add_argument(
        '-f', '--file', default='custom-resources.yaml',
        help='Path to calico custom resources manifest'
    )
    parser.add_argument(
        '-i', '--interface', required=True,
        help='Interface to be used by calico (ex: eth0)'
    )
    default_cidr='10.10.0.0/16'
    parser.add_argument(
        '-c', '--cidr', default=default_cidr,
        help='CIDR Rage (ex: {}).'.format(default_cidr)
    )
    return parser.parse_args()

def main():
    args = parse_args()
    file_path = args.file
    interface = args.interface
    cidr = args.cidr

    # Read whole file
    with open(file_path) as f:
        documents = list(yaml.safe_load_all(f))

    # Modify config
    for doc in documents:
        if doc.get('kind') == 'Installation':
            doc['spec']['calicoNetwork']['nodeAddressAutodetectionV4'] = {
                'firstFound': False,
                'interface': interface
            }
            doc['spec']['calicoNetwork']['ipPools'][0]['cidr'] = cidr

    # Inplace modification
    with open(file_path, 'w') as f:
        yaml.dump_all(documents, f, sort_keys=False, default_flow_style=False)

if __name__ == '__main__':
    main()

