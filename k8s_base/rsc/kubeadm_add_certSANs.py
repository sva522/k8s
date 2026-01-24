#!/usr/bin/env python3

import subprocess
import yaml
from time import sleep
from sys import argv, exit
from os import remove
import requests
from shutil import which
from time import sleep

blue = '\033[34;1m'
grey = '\033[90;1m'
red = '\033[31;1m'
green = '\033[32;1m'
nocolor = '\033[0m'

def run(cmd, capture=True):
    '''Run a shell command and optionally capture output.'''
    if capture:
        return subprocess.check_output(cmd, shell=True, text=True).strip()
    else:
        subprocess.check_call(cmd, shell=True)

def print_current_sans():
    '''Display the current SANs from the apiserver certificate.'''
    print(f'{blue}Current SANs of the apiserver certificate:{nocolor}')
    try:
        out = run(
            'openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -text | '
            "grep -A1 'Subject Alternative Name'"
        )
        if not isinstance(out, str):
            raise Exception('No output from openssl command')
        # Get second lines only
        out = out.split('\n')[1]
        out = out.replace('DNS:', '').replace('IP Address:', '').strip()
        print(out)
    except Exception:
        print(f'{red}Unable to read /etc/kubernetes/pki/apiserver.crt (check permissions?){nocolor}')

def fetch_cluster_config() -> dict:
    raw = None
    attempts = 6
    while not raw and attempts > 0:
        attempts -= 1
        try:
            raw = run("kubectl -n kube-system get cm kubeadm-config -o jsonpath='{.data.ClusterConfiguration}'")
        except Exception as e:
            sleep(2)
    if not raw:
        raise Exception('Failed to fetch ClusterConfiguration from kubeadm ConfigMap')
    return yaml.safe_load(raw)

def modify_config(cluster_conf: dict):
    # Retrieve current certSANs from ClusterConfiguration
    api = cluster_conf.get('apiServer', {})
    certSANs = api.get('certSANs', [])
    print('certSANs in current ClusterConfiguration:', ' '.join(certSANs))

    # Append additional SANs from command-line arguments
    certSANs += argv[1:]
    certSANs = list(dict.fromkeys(certSANs))
    #api['extraArgs']['advertise-address']=''
    print('Final certSANs list:', ' '.join(certSANs))
    cluster_conf['apiServer']['certSANs'] = certSANs

def show_yaml_with_batcat(yaml_text: str, title: str):
    # Check if batcat is available
    bat = which('batcat') or which('bat')
    if bat:
        # Send yaml_text directly to batcat via stdin
        subprocess.run([bat, '--language', 'yaml', '--file-name', title], input=yaml_text.encode(), check=True)
    else:
        # Fallback: just print the YAML text
        print(yaml_text)

def regenerate_apiserver_cert(certSANs_yaml_text: str):
    cert_file = '/etc/kubernetes/pki/apiserver.crt'
    key_file = '/etc/kubernetes/pki/apiserver.key'
    print(f'{blue}Regenerating apiserver certificates...{nocolor}')
    run('systemctl stop kubelet', capture=False)
    try:
        remove(cert_file)
        remove(key_file)
    except FileNotFoundError:
        print(f'{red}Old cert/key not found (already removed or not present).{nocolor}')
    except Exception as e:
        print(f'{red}ERROR removing old cert/key: {e}{nocolor}')
        exit(1)

    # Regenerate the apiserver certificate using kubeadm
    proc = subprocess.Popen(
        ['kubeadm', 'init', 'phase', 'certs', 'apiserver', '--config', '/dev/stdin'],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    out, err = proc.communicate(certSANs_yaml_text)
    out = out.strip()
    err = err.strip()
    print(f'{grey}{out}\n{err}{nocolor}')
    print('Modified files:')
    print(cert_file)
    print(key_file)

    if proc.returncode != 0:
        print(f'{red}ERROR running kubeadm:', err, nocolor)
        exit(2)

    run('systemctl start kubelet', capture=False)
    print('Done.')

def wait_for_cert_regeneration(max_wait=30):
    '''Wait for kubelet to reload the apiserver certificate.'''
    print(f'{blue}Waiting for kubelet to reload the certificate...{nocolor}')
    for _ in range(max_wait):
        try:
            run('openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout')
            print(f'{green}Done.{nocolor}')
            return
        except:
            sleep(2)
    print(f'{red}kubelet has not generated certificate.{nocolor}')
    exit(3)

def wait_for_kubelet_reload(max_wait=30, api_server='https://127.0.0.1:6443/healthz', ca_cert='/etc/kubernetes/pki/ca.crt'):
    print(f'{blue}Waiting for API server to become healthy...{nocolor}')
    for _ in range(max_wait):
        try:
            r = requests.get(api_server, verify=ca_cert, timeout=2)
            if r.status_code == 200 and r.text.strip() == 'ok':
                print(f'{green}API server is started.{nocolor}')
                break
        except Exception:
            pass
        sleep(1)
    else:
        print(f'{red}API server is not healthy after {max_wait} seconds.{nocolor}')
        exit(4)

def main():
    print_current_sans()
    cluster_conf = fetch_cluster_config()
    modify_config(cluster_conf)

    certSANs_yaml_text = yaml.dump(cluster_conf, sort_keys=False)
    certSANs_yaml_text += '\n---\n'
    with open('/root/kubeadm-init.yaml', encoding='utf-8') as f:
        certSANs_yaml_text += f.read()
    
    show_yaml_with_batcat(certSANs_yaml_text, 'CertSANs config')
    regenerate_apiserver_cert(certSANs_yaml_text)

    wait_for_cert_regeneration()
    wait_for_kubelet_reload()
    print_current_sans()

if __name__ == '__main__':
    main()
