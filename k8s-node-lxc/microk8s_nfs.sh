#!/bin/bash

cwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $cwd

apt update 
apt install nfs-kernel-server -y
mkdir -p $2
chown nobody:nogroup $2
chmod 0777 $2
mv /etc/exports /etc/exports.bak
echo "$2 $1/24(rw,sync,no_subtree_check)" | tee /etc/exports
systemctl restart nfs-kernel-server

microk8s helm3 repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
microk8s helm3 repo update
microk8s helm3 install csi-driver-nfs csi-driver-nfs/csi-driver-nfs \
    --namespace kube-system \
    --set kubeletDir=/var/snap/microk8s/common/var/lib/kubelet
microk8s kubectl wait pod --selector app.kubernetes.io/name=csi-driver-nfs --for condition=ready --namespace kube-system

tee ./sc-nfs.yaml > /dev/null <<EOF
# sc-nfs.yaml
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-csi
provisioner: nfs.csi.k8s.io
parameters:
  server: $1
  share: $2
reclaimPolicy: Delete
volumeBindingMode: Immediate
mountOptions:
  - hard
  - nfsvers=4.1
EOF

microk8s kubectl apply -f ./sc-nfs.yaml
microk8s kubectl patch storageclass nfs-csi -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'