#!/bin/bash

cwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $cwd

K8SID=$1
K8SNAME=$2
RANDMAC=$(printf "%02X:%02X:%02X:%02X:%02X:%02X" $[RANDOM%256] $[RANDOM%256] $[RANDOM%256] $[RANDOM%256] $[RANDOM%256] $[RANDOM%256])

pct stop ${K8SID}

tee -a /etc/pve/lxc/${K8SID}.conf > /dev/null <<EOF
net1: name=eth1,bridge=k8snet,firewall=1,hwaddr=${RANDMAC},ip=192.168.0.${K8SID}/24,type=veth,mtu=1450
lxc.apparmor.profile: unconfined
lxc.cgroup.devices.allow: a
lxc.cap.drop:
lxc.mount.auto: "proc:rw sys:rw"
lxc.mount.entry = /dev/fuse dev/fuse none bind,create=file 0 0
EOF

pct start ${K8SID}

pct push ${K8SID} /boot/config-$(uname -r) /boot/config-$(uname -r)
pct push ${K8SID} ${cwd}/conf-kmsg.service /etc/systemd/system/conf-kmsg.service
pct push ${K8SID} ${cwd}/k8s-hosts /opt/k8s-hosts
pct push ${K8SID} ${cwd}/conf-kmsg.sh /usr/local/bin/conf-kmsg.sh --perms 755
pct push ${K8SID} ${cwd}/rc.local /etc/rc.local --perms 755
pct push ${K8SID} ${cwd}/microk8s_init.sh /opt/microk8s_init.sh --perms 755
pct push ${K8SID} ${cwd}/microk8s_addons.sh /opt/microk8s_addons.sh --perms 755
pct push ${K8SID} ${cwd}/microk8s_nfs.sh /opt/microk8s_nfs.sh --perms 755
pct push ${K8SID} ${cwd}/microk8s_portainer.sh /opt/microk8s_portainer.sh --perms 755

pct exec ${K8SID} "/opt/microk8s_init.sh"
pct reboot ${K8SID}
pct exec ${K8SID} "/opt/microk8s_zfs.sh"