Voici la configuration ip de mon premier noeud.
```
aadmin@k8s1:~$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: ens3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:6e:9e:f0 brd ff:ff:ff:ff:ff:ff
    altname enp0s3
    altname enx5254006e9ef0
    inet 192.168.10.101/24 metric 100 brd 192.168.10.255 scope global dynamic ens3
       valid_lft 1032sec preferred_lft 1032sec
    inet6 fe80::5054:ff:fe6e:9ef0/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
3: ens4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:fa:b1:bb brd ff:ff:ff:ff:ff:ff
    altname enp0s4
    altname enx525400fab1bb
    inet 192.168.11.1/24 brd 192.168.11.255 scope global deprecated ens4
       valid_lft forever preferred_lft forever
    inet 192.168.11.11/24 metric 100 brd 192.168.11.255 scope global secondary dynamic ens4
       valid_lft 133sec preferred_lft 133sec
    inet6 fe80::5054:ff:fefa:b1bb/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
4: ens5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:4a:c7:5a brd ff:ff:ff:ff:ff:ff
    altname enp0s5
    altname enx5254004ac75a
    inet 192.168.12.11/24 metric 100 brd 192.168.12.255 scope global dynamic ens5
       valid_lft 134sec preferred_lft 134sec
    inet6 fe80::5054:ff:fe4a:c75a/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
5: ens6: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:02:ca:d5 brd ff:ff:ff:ff:ff:ff
    altname enp0s6
    altname enx52540002cad5
    inet 192.168.13.11/24 metric 100 brd 192.168.13.255 scope global dynamic ens6
       valid_lft 132sec preferred_lft 132sec
    inet6 fe80::5054:ff:fe02:cad5/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
6: ens7: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:7a:29:89 brd ff:ff:ff:ff:ff:ff
    altname enp0s7
    altname enx5254007a2989
    inet 192.168.14.11/24 metric 100 brd 192.168.14.255 scope global dynamic ens7
       valid_lft 131sec preferred_lft 131sec
    inet6 fe80::5054:ff:fe7a:2989/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
7: calid135a52c392@if2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default qlen 1000
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netns cni-7cc5f6d2-a776-8704-7fc8-d70a54e5c824
8: cali17c95e8bfa9@if2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default qlen 1000
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netns cni-7a5b3d46-16d9-0bfc-3803-34e547e1ae3b
9: cali35c85a60edf@if2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default qlen 1000
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netns cni-51c339b5-4379-570a-6bd4-42ee867dff96
10: cali752d89f3915@if2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default qlen 1000
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netns cni-81391d6a-2b72-7ec4-d792-a7d1c2976efa
11: calid5835c6dcad@if2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default qlen 1000
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netns cni-3aff8cb7-22d2-c369-f7a3-b5bd35136e1c
12: calia965db4979b@if2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default qlen 1000
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netns cni-5a6f7c12-ea66-f929-cd07-b6cfe9af1d69
13: cali78f1035cd96@if2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default qlen 1000
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netns cni-8e6dae5d-35f6-6616-75c6-eee3b9fc7769
14: cali4703ecc6782@if2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default qlen 1000
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netns cni-072a53d8-16e7-5695-69d7-5efffcc8ae53
15: califc59edcedb9@if2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default qlen 1000
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netns cni-dce683ea-54e5-6b1c-6599-915594c0741a
16: cali84e504585c8@if2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default qlen 1000
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netns cni-a13d7efe-0162-e488-da03-c5a2863481d2
17: calia0e2ecb88fd@if2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default qlen 1000
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netns cni-c362ea6f-fa00-88a7-f030-6ab6bfda7044
18: vxlan.calico: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN group default qlen 1000
    link/ether 66:4e:03:0e:15:0e brd ff:ff:ff:ff:ff:ff
    inet 10.10.166.192/32 scope global vxlan.calico
       valid_lft forever preferred_lft forever
```

Et sur mon deuxième noeud :
```
admin@k8s2:~$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: ens3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:52:ab:f3 brd ff:ff:ff:ff:ff:ff
    altname enp0s3
    altname enx52540052abf3
    inet 192.168.10.102/24 metric 100 brd 192.168.10.255 scope global dynamic ens3
       valid_lft 2886sec preferred_lft 2886sec
    inet6 fe80::5054:ff:fe52:abf3/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
3: ens4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:de:b4:c4 brd ff:ff:ff:ff:ff:ff
    altname enp0s4
    altname enx525400deb4c4
    inet 192.168.11.12/24 metric 100 brd 192.168.11.255 scope global dynamic ens4
       valid_lft 188sec preferred_lft 188sec
    inet6 fe80::5054:ff:fede:b4c4/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
4: ens5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:6a:4b:6e brd ff:ff:ff:ff:ff:ff
    altname enp0s5
    altname enx5254006a4b6e
    inet 192.168.12.12/24 metric 100 brd 192.168.12.255 scope global dynamic ens5
       valid_lft 185sec preferred_lft 185sec
    inet6 fe80::5054:ff:fe6a:4b6e/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
5: ens6: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:72:aa:13 brd ff:ff:ff:ff:ff:ff
    altname enp0s6
    altname enx52540072aa13
    inet 192.168.13.12/24 metric 100 brd 192.168.13.255 scope global dynamic ens6
       valid_lft 186sec preferred_lft 186sec
    inet6 fe80::5054:ff:fe72:aa13/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
6: ens7: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:8a:91:4b brd ff:ff:ff:ff:ff:ff
    altname enp0s7
    altname enx5254008a914b
    inet 192.168.14.12/24 metric 100 brd 192.168.14.255 scope global dynamic ens7
       valid_lft 188sec preferred_lft 188sec
    inet6 fe80::5054:ff:fe8a:914b/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
7: cali6ff53458f8d@if2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netns cni-c3fe24f0-1b43-96a5-460d-ff147ddb690b
10: vxlan.calico: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN group default qlen 1000
    link/ether 66:aa:13:16:c8:2d brd ff:ff:ff:ff:ff:ff
    inet 10.10.109.64/32 scope global vxlan.calico
       valid_lft forever preferred_lft forever
12: cali5906de6399d@if2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default qlen 1000
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netns cni-56cfd77b-eba9-0042-f92a-d040dfaa7cd2
```
Et sur mon troisième noeud :
```
admin@k8s3:~$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: ens3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:d2:ff:6b brd ff:ff:ff:ff:ff:ff
    altname enp0s3
    altname enx525400d2ff6b
    inet 192.168.10.103/24 metric 100 brd 192.168.10.255 scope global dynamic ens3
       valid_lft 946sec preferred_lft 946sec
    inet6 fe80::5054:ff:fed2:ff6b/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
3: ens4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:66:92:bd brd ff:ff:ff:ff:ff:ff
    altname enp0s4
    altname enx5254006692bd
    inet 192.168.11.13/24 metric 100 brd 192.168.11.255 scope global dynamic ens4
       valid_lft 174sec preferred_lft 174sec
    inet6 fe80::5054:ff:fe66:92bd/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
4: ens5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:0e:2d:c7 brd ff:ff:ff:ff:ff:ff
    altname enp0s5
    altname enx5254000e2dc7
    inet 192.168.12.13/24 metric 100 brd 192.168.12.255 scope global dynamic ens5
       valid_lft 175sec preferred_lft 175sec
    inet6 fe80::5054:ff:fe0e:2dc7/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
5: ens6: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:56:91:26 brd ff:ff:ff:ff:ff:ff
    altname enp0s6
    altname enx525400569126
    inet 192.168.13.13/24 metric 100 brd 192.168.13.255 scope global dynamic ens6
       valid_lft 175sec preferred_lft 175sec
    inet6 fe80::5054:ff:fe56:9126/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
6: ens7: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:3a:fb:1c brd ff:ff:ff:ff:ff:ff
    altname enp0s7
    altname enx5254003afb1c
    inet 192.168.14.13/24 metric 100 brd 192.168.14.255 scope global dynamic ens7
       valid_lft 180sec preferred_lft 180sec
    inet6 fe80::5054:ff:fe3a:fb1c/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
7: cali003e27c87d6@if2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netns cni-ce5d5093-9c50-dd1e-8f07-04fe7414738c
8: vxlan.calico: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN group default qlen 1000
    link/ether 66:70:f7:58:e4:2b brd ff:ff:ff:ff:ff:ff
    inet 10.10.219.0/32 scope global vxlan.calico
       valid_lft forever preferred_lft forever
11: cali3ffb27b7fae@if2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default qlen 1000
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netns cni-4d0756bf-6690-d2f0-feb0-15bde106a802
13: cali381e1dc5e0c@if2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default qlen 1000
    link/ether ee:ee:ee:ee:ee:ee brd ff:ff:ff:ff:ff:ff link-netns cni-a68f6a23-4797-0c91-0929-341a51d81817
```
L'état des noeuds est bon:
```
k get nodes -o wide
NAME   STATUS   ROLES                  AGE     VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                       KERNEL-VERSION        CONTAINER-RUNTIME
k8s1   Ready    control-plane,worker   3h32m   v1.34.3   192.168.11.11   <none>        Debian GNU/Linux 13 (trixie)   6.12.63+deb13-amd64   containerd://1.7.24
k8s2   Ready    control-plane,worker   102m    v1.34.3   192.168.11.12   <none>        Debian GNU/Linux 13 (trixie)   6.12.48+deb13-amd64   containerd://1.7.24
k8s3   Ready    control-plane,worker   101m    v1.34.3   192.168.11.13   <none>        Debian GNU/Linux 13 (trixie)   6.12.48+deb13-amd64   containerd://1.7.24
```